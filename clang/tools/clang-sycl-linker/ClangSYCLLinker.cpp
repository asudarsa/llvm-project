//=-------- clang-sycl-linker/ClangSYCLLinker.cpp - SYCL Linker util -------=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===---------------------------------------------------------------------===//
//
// This tool executes a sequence of steps required to link device code in SYCL
// device images. SYCL device code linking requires a complex sequence of steps
// that include linking of llvm bitcode files, linking device library files
// with the fully linked source bitcode file(s), running several SYCL specific
// post-link steps on the fully linked bitcode file(s), and finally generating
// target-specific device code.
//===---------------------------------------------------------------------===//

#include "clang/Basic/Version.h"

#include "llvm/ADT/StringExtras.h"
#include "llvm/BinaryFormat/Magic.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/CodeGen/CommandFlags.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/LTO/LTO.h"
#include "llvm/Linker/Linker.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Object/Archive.h"
#include "llvm/Object/ArchiveWriter.h"
#include "llvm/Object/Binary.h"
#include "llvm/Object/ELFObjectFile.h"
#include "llvm/Object/IRObjectFile.h"
#include "llvm/Object/ObjectFile.h"
#include "llvm/Object/OffloadBinary.h"
#include "llvm/Option/ArgList.h"
#include "llvm/Option/OptTable.h"
#include "llvm/Option/Option.h"
#include "llvm/Remarks/HotnessThresholdParser.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileOutputBuffer.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/Program.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/StringSaver.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/TimeProfiler.h"
#include "llvm/Support/WithColor.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Transforms/IPO/GlobalDCE.h"
#include "llvm/Transforms/Utils/SYCLSplitModule.h"
#include "llvm/Transforms/Utils/SYCLUtils.h"

using namespace llvm;
using namespace llvm::opt;
using namespace llvm::object;

/// Save intermediary results.
static bool SaveTemps = false;

/// Print arguments without executing.
static bool DryRun = false;

/// Print verbose output.
static bool Verbose = false;

/// Filename of the output being created.
static StringRef OutputFile;

/// Directory to dump SPIR-V IR if requested by user.
static SmallString<128> SPIRVDumpDir;

static void printVersion(raw_ostream &OS) {
  OS << clang::getClangToolFullVersion("clang-sycl-linker") << '\n';
}

/// The value of `argv[0]` when run.
static const char *Executable;

/// Mutex lock to protect writes to shared TempFiles in parallel.
static std::mutex TempFilesMutex;

/// Temporary files to be cleaned up.
static SmallVector<SmallString<128>> TempFiles;

using OffloadingImage = OffloadBinary::OffloadingImage;

namespace {
// Must not overlap with llvm::opt::DriverFlag.
enum LinkerFlags { LinkerOnlyOption = (1 << 4) };

enum ID {
  OPT_INVALID = 0, // This is not an option ID.
#define OPTION(...) LLVM_MAKE_OPT_ID(__VA_ARGS__),
#include "SYCLLinkOpts.inc"
  LastOption
#undef OPTION
};

#define OPTTABLE_STR_TABLE_CODE
#include "SYCLLinkOpts.inc"
#undef OPTTABLE_STR_TABLE_CODE

#define OPTTABLE_PREFIXES_TABLE_CODE
#include "SYCLLinkOpts.inc"
#undef OPTTABLE_PREFIXES_TABLE_CODE

static constexpr OptTable::Info InfoTable[] = {
#define OPTION(...) LLVM_CONSTRUCT_OPT_INFO(__VA_ARGS__),
#include "SYCLLinkOpts.inc"
#undef OPTION
};

class LinkerOptTable : public opt::GenericOptTable {
public:
  LinkerOptTable()
      : opt::GenericOptTable(OptionStrTable, OptionPrefixesTable, InfoTable) {}
};

const OptTable &getOptTable() {
  static const LinkerOptTable *Table = []() {
    auto Result = std::make_unique<LinkerOptTable>();
    return Result.release();
  }();
  return *Table;
}

[[noreturn]] void reportError(Error E) {
  outs().flush();
  logAllUnhandledErrors(std::move(E), WithColor::error(errs(), Executable));
  exit(EXIT_FAILURE);
}

Expected<StringRef> createTempFile(const ArgList &Args, const Twine &Prefix,
                                   StringRef Extension) {
  SmallString<128> OutputFile;
  if (Args.hasArg(OPT_save_temps)) {
    // Generate a unique path name without creating a file
    sys::fs::createUniquePath(Prefix + "-%%%%%%." + Extension, OutputFile,
                              /*MakeAbsolute=*/false);
  } else {
    if (std::error_code EC =
            sys::fs::createTemporaryFile(Prefix, Extension, OutputFile))
      return createFileError(OutputFile, EC);
  }

  TempFiles.emplace_back(std::move(OutputFile));
  return TempFiles.back();
}

/// Get a temporary filename suitable for output.
Expected<StringRef> createOutputFile(const Twine &Prefix, StringRef Extension) {
  std::scoped_lock<decltype(TempFilesMutex)> Lock(TempFilesMutex);
  SmallString<128> OutputFile;
  if (SaveTemps) {
    (Prefix + "." + Extension).toNullTerminatedStringRef(OutputFile);
  } else {
    if (std::error_code EC =
            sys::fs::createTemporaryFile(Prefix, Extension, OutputFile))
      return createFileError(OutputFile, EC);
  }

  TempFiles.emplace_back(std::move(OutputFile));
  return TempFiles.back();
}

Expected<StringRef> writeOffloadFile(const OffloadFile &File) {
  const OffloadBinary &Binary = *File.getBinary();

  StringRef Prefix =
      sys::path::stem(Binary.getMemoryBufferRef().getBufferIdentifier());
  SmallString<128> Filename;
  (Prefix + "-" + Binary.getTriple() + "-" + Binary.getArch())
      .toVector(Filename);
  llvm::replace(Filename, ':', '-');
  auto TempFileOrErr = createOutputFile(Filename, "o");
  if (!TempFileOrErr)
    return TempFileOrErr.takeError();

  Expected<std::unique_ptr<FileOutputBuffer>> OutputOrErr =
      FileOutputBuffer::create(*TempFileOrErr, Binary.getImage().size());
  if (!OutputOrErr)
    return OutputOrErr.takeError();
  std::unique_ptr<FileOutputBuffer> Output = std::move(*OutputOrErr);
  llvm::copy(Binary.getImage(), Output->getBufferStart());
  if (Error E = Output->commit())
    return std::move(E);

  return *TempFileOrErr;
}

static Error writeFile(StringRef Filename, StringRef Data) {
  Expected<std::unique_ptr<FileOutputBuffer>> OutputOrErr =
      FileOutputBuffer::create(Filename, Data.size());
  if (!OutputOrErr)
    return OutputOrErr.takeError();
  std::unique_ptr<FileOutputBuffer> Output = std::move(*OutputOrErr);
  llvm::copy(Data, Output->getBufferStart());
  if (Error E = Output->commit())
    return E;
  return Error::success();
}

Expected<SmallVector<std::string>> getInput(const ArgList &Args) {
  // Collect all input bitcode files to be passed to the device linking stage.
  SmallVector<std::string> BitcodeFiles;
  for (const opt::Arg *Arg : Args.filtered(OPT_INPUT)) {
    std::optional<std::string> Filename = std::string(Arg->getValue());
    if (!Filename || !sys::fs::exists(*Filename) ||
        sys::fs::is_directory(*Filename))
      continue;
    file_magic Magic;
    if (auto EC = identify_magic(*Filename, Magic))
      return createStringError("Failed to open file " + *Filename);
    // TODO: Current use case involves LLVM IR bitcode files as input.
    // This will be extended to support SPIR-V IR files.
    if (Magic != file_magic::bitcode)
      return createStringError("Unsupported file type");
    BitcodeFiles.push_back(*Filename);
  }
  return BitcodeFiles;
}

/// Handle cases where input file is a LLVM IR bitcode file.
/// When clang-sycl-linker is called via clang-linker-wrapper tool, input files
/// are LLVM IR bitcode files.
// TODO: Support SPIR-V IR files.
Expected<std::unique_ptr<Module>> getBitcodeModule(StringRef File,
                                                   LLVMContext &C) {
  SMDiagnostic Err;

  auto M = getLazyIRFileModule(File, Err, C);
  if (M)
    return std::move(M);
  return createStringError(Err.getMessage());
}

/// Gather all SYCL device library files that will be linked with input device
/// files.
/// The list of files and its location are passed from driver.
Expected<SmallVector<std::string>> getSYCLDeviceLibs(const ArgList &Args) {
  SmallVector<std::string> DeviceLibFiles;
  StringRef LibraryPath;
  if (Arg *A = Args.getLastArg(OPT_library_path_EQ))
    LibraryPath = A->getValue();
  if (Arg *A = Args.getLastArg(OPT_device_libs_EQ)) {
    if (A->getValues().size() == 0)
      return createStringError(
          inconvertibleErrorCode(),
          "Number of device library files cannot be zero.");
    for (StringRef Val : A->getValues()) {
      SmallString<128> LibName(LibraryPath);
      llvm::sys::path::append(LibName, Val);
      if (llvm::sys::fs::exists(LibName))
        DeviceLibFiles.push_back(std::string(LibName));
      else
        return createStringError(inconvertibleErrorCode(),
                                 "\'" + std::string(LibName) + "\'" +
                                     " SYCL device library file is not found.");
    }
  }
  return DeviceLibFiles;
}

/// Following tasks are performed:
/// 1. Link all SYCL device bitcode images into one image. Device linking is
/// performed using the linkInModule API.
/// 2. Gather all SYCL device library bitcode images.
/// 3. Link all the images gathered in Step 2 with the output of Step 1 using
/// linkInModule API. LinkOnlyNeeded flag is used.
Expected<StringRef> linkDeviceCode(ArrayRef<std::string> InputFiles,
                                   const ArgList &Args, LLVMContext &C) {
  llvm::TimeTraceScope TimeScope("SYCL link device code");

  assert(InputFiles.size() && "No inputs to link");

  auto LinkerOutput = std::make_unique<Module>("sycl-device-link", C);
  Linker L(*LinkerOutput);
  // Link SYCL device input files.
  for (auto &File : InputFiles) {
    auto ModOrErr = getBitcodeModule(File, C);
    if (!ModOrErr)
      return ModOrErr.takeError();
    if (L.linkInModule(std::move(*ModOrErr)))
      return createStringError("Could not link IR");
  }

  // Get all SYCL device library files, if any.
  auto SYCLDeviceLibFiles = getSYCLDeviceLibs(Args);
  if (!SYCLDeviceLibFiles)
    return SYCLDeviceLibFiles.takeError();

  // Link in SYCL device library files.
  const llvm::Triple Triple(Args.getLastArgValue(OPT_triple_EQ));
  for (auto &File : *SYCLDeviceLibFiles) {
    auto LibMod = getBitcodeModule(File, C);
    if (!LibMod)
      return LibMod.takeError();
    if ((*LibMod)->getTargetTriple() == Triple) {
      unsigned Flags = Linker::Flags::LinkOnlyNeeded;
      if (L.linkInModule(std::move(*LibMod), Flags))
        return createStringError("Could not link IR");
    }
  }

  // Dump linked output for testing.
  if (Args.hasArg(OPT_print_linked_module))
    outs() << *LinkerOutput;

  // Create a new file to write the linked device file to.
  auto BitcodeOutput =
      createTempFile(Args, sys::path::filename(OutputFile), "bc");
  if (!BitcodeOutput)
    return BitcodeOutput.takeError();

  // Write the final output into 'BitcodeOutput' file.
  int FD = -1;
  if (std::error_code EC = sys::fs::openFileForWrite(*BitcodeOutput, FD))
    return errorCodeToError(EC);
  llvm::raw_fd_ostream OS(FD, true);
  WriteBitcodeToFile(*LinkerOutput, OS);

  if (Verbose) {
    std::string Inputs = llvm::join(InputFiles.begin(), InputFiles.end(), ", ");
    std::string LibInputs = llvm::join((*SYCLDeviceLibFiles).begin(),
                                       (*SYCLDeviceLibFiles).end(), ", ");
    errs() << formatv(
        "sycl-device-link: inputs: {0} libfiles: {1} output: {2}\n", Inputs,
        LibInputs, *BitcodeOutput);
  }

  return *BitcodeOutput;
}

void cleanupModule(Module &M) {
  ModuleAnalysisManager MAM;
  MAM.registerPass([&] { return PassInstrumentationAnalysis(); });
  ModulePassManager MPM;
  MPM.addPass(GlobalDCEPass()); // Delete unreachable globals.
  MPM.run(M, MAM);
}

void writeModuleToFile(const Module &M, StringRef Path, bool OutputAssembly) {
  int FD = -1;
  if (std::error_code EC = sys::fs::openFileForWrite(Path, FD)) {
    errs() << formatv("error opening file: {0}, error: {1}", Path, EC.message())
           << '\n';
    exit(1);
  }

  raw_fd_ostream OS(FD, /*ShouldClose*/ true);
  if (OutputAssembly)
    M.print(OS, /*AssemblyAnnotationWriter*/ nullptr);
  else
    WriteBitcodeToFile(M, OS);
}

Expected<SmallVector<ModuleAndSYCLMetadata>> runSYCLSplitModule(std::unique_ptr<Module> M, const ArgList &Args) {
  SmallVector<ModuleAndSYCLMetadata> SplitModules;
  if (Error Err = M->materializeAll())
    return std::move(Err);
  auto PostSYCLSplitCallback = [&](std::unique_ptr<Module> MPart,
                                   std::string Symbols) {
    if (verifyModule(*MPart)) {
      errs() << "Broken Module!\n";
      exit(1);
    }
    if (Error Err = MPart->materializeAll()) {
      errs() << "Broken Module!\n";
      exit(1);
    }
    // TODO: DCE is a crucial pass in a SYCL post-link pipeline.
    //       At the moment, LIT checking can't be perfomed without DCE.
    cleanupModule(*MPart);
    size_t ID = SplitModules.size();
    StringRef ModuleSuffix = ".bc";
    std::string ModulePath =
        (Twine(OutputFile) + "_post_link_" + Twine(ID) + ModuleSuffix).str();
    writeModuleToFile(*MPart, ModulePath, /* OutputAssembly */ false);
    SplitModules.emplace_back(std::move(ModulePath), std::move(Symbols));
  };

  StringRef Mode = Args.getLastArgValue(OPT_sycl_split_mode_EQ);
  auto SYCLSplitMode = StringSwitch<IRSplitMode>(Mode)
  .Case("per_source", IRSplitMode::IRSM_PER_TU)
  .Case("per_kernel", IRSplitMode::IRSM_PER_KERNEL)
  .Case("none", IRSplitMode::IRSM_NONE)
  .Default(IRSplitMode::IRSM_NONE);
  SYCLSplitModule(std::move(M), SYCLSplitMode, PostSYCLSplitCallback);

  if (Verbose) {
    std::string OutputFiles;
    for (size_t I = 0, E = SplitModules.size(); I != E; ++I) {
      OutputFiles.append(SplitModules[I].ModuleFilePath);
      OutputFiles.append("\n");
    }
    errs() << formatv("sycl-module-split: outputs:\n{0}\n", OutputFiles); 
  }
  return SplitModules;
}

/// Run LLVM to SPIR-V translation.
/// Converts 'File' from LLVM bitcode to SPIR-V format using SPIR-V backend.
/// 'Args' encompasses all arguments required for linking device code and will
/// be parsed to generate options required to be passed into the backend.
static Error runSPIRVCodeGen(StringRef File, const ArgList &Args,
                                           StringRef SPVFile, LLVMContext &C) {
  llvm::TimeTraceScope TimeScope("SPIR-V code generation");

  // Parse input module.
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseIRFile(File, Err, C);
  if (!M)
    return createStringError(Err.getMessage());

  if (Error Err = M->materializeAll())
    return std::move(Err);
                                        
  Triple TargetTriple(Args.getLastArgValue(OPT_triple_EQ));
  M->setTargetTriple(TargetTriple);

  // Get a handle to SPIR-V target backend.
  std::string Msg;
  const Target *T = TargetRegistry::lookupTarget(M->getTargetTriple(), Msg);
  if (!T)
    return createStringError(Msg + ": " + M->getTargetTriple().str());

  // Allocate SPIR-V target machine.
  TargetOptions Options;
  std::optional<Reloc::Model> RM;
  std::optional<CodeModel::Model> CM;
  std::unique_ptr<TargetMachine> TM(
      T->createTargetMachine(M->getTargetTriple(), /* CPU */ "",
                             /* Features */ "", Options, RM, CM));
  if (!TM)
    return createStringError("Could not allocate target machine!");

  // Set data layout if needed.
  if (M->getDataLayout().isDefault())
    M->setDataLayout(TM->createDataLayout());

  // Open output file for writing.
  int FD = -1;
  if (std::error_code EC = sys::fs::openFileForWrite(SPVFile, FD))
    return errorCodeToError(EC);
  auto OS = std::make_unique<llvm::raw_fd_ostream>(FD, true);

  // Run SPIR-V codegen passes to generate SPIR-V file.
  legacy::PassManager CodeGenPasses;
  TargetLibraryInfoImpl TLII(M->getTargetTriple());
  CodeGenPasses.add(new TargetLibraryInfoWrapperPass(TLII));
  if (TM->addPassesToEmitFile(CodeGenPasses, *OS, nullptr,
                              CodeGenFileType::ObjectFile))
    return createStringError("Failed to execute SPIR-V Backend");
  CodeGenPasses.run(*M);

  if (Verbose)
    errs() << formatv("SPIR-V Backend: input: {0}, output: {1}\n", File,
                      SPVFile);

  return Error::success();
}

/// Performs the following steps:
/// 1. Link input device code (user code and SYCL device library code).
/// 2. Run SPIR-V code generation.
Error runSYCLLink(ArrayRef<std::string> Files, const ArgList &Args) {
  llvm::TimeTraceScope TimeScope("SYCL device linking");

  std::mutex ImageMtx;
  LLVMContext C;

  // Link all input bitcode files and SYCL device library files, if any.
  auto LinkedFile = linkDeviceCode(Files, Args, C);
  if (!LinkedFile)
    reportError(LinkedFile.takeError());

  auto LinkedModule = getBitcodeModule(*LinkedFile, C);
  if (!LinkedModule)
    return LinkedModule.takeError();
  // sycl-post-link step
  auto SplitModules = runSYCLSplitModule(std::move(*LinkedModule), Args);
  if (!SplitModules)
    reportError(SplitModules.takeError());

  // SPIR-V code generation step.
  for (size_t I = 0, E = (*SplitModules).size(); I != E; ++I) {
    std::string SPVFile(OutputFile);
    SPVFile.append(utostr(I));
    auto Err = runSPIRVCodeGen((*SplitModules)[I].ModuleFilePath, Args, SPVFile, C);
    if (Err)
      return std::move(Err);
    (*SplitModules)[I].ModuleFilePath = SPVFile;
  }

  SmallVector<char, 1024> BinaryData;
  raw_svector_ostream OS(BinaryData);
  for (size_t I = 0, E = (*SplitModules).size(); I != E; ++I) {
    auto File = (*SplitModules)[I].ModuleFilePath;
    llvm::ErrorOr<std::unique_ptr<llvm::MemoryBuffer>> FileOrErr =
        llvm::MemoryBuffer::getFileOrSTDIN(File);
    if (std::error_code EC = FileOrErr.getError()) {
      if (DryRun)
        FileOrErr = MemoryBuffer::getMemBuffer("");
      else
        return createFileError(File, EC);
    }

    std::scoped_lock<decltype(ImageMtx)> Guard(ImageMtx);
    OffloadingImage TheImage{};
    TheImage.TheImageKind = IMG_Object;
    TheImage.TheOffloadKind = OFK_SYCL;
    TheImage.StringData["triple"] =
        Args.MakeArgString(Args.getLastArgValue(OPT_triple_EQ));
    TheImage.StringData["arch"] =
        Args.MakeArgString(Args.getLastArgValue(OPT_arch_EQ));
    TheImage.Image = std::move(*FileOrErr);

    llvm::SmallString<0> Buffer = OffloadBinary::write(TheImage);
    if (Buffer.size() % OffloadBinary::getAlignment() != 0)
      return createStringError(inconvertibleErrorCode(),
                                "Offload binary has invalid size alignment");
    OS << Buffer;
  }
  if (Error E = writeFile(OutputFile,
    StringRef(BinaryData.begin(), BinaryData.size())))
    return E;
 
  {
    ErrorOr<std::unique_ptr<MemoryBuffer>> BufferOrErr =
      MemoryBuffer::getFileOrSTDIN(OutputFile);
    if (std::error_code EC = BufferOrErr.getError())
      return createFileError(OutputFile, EC);

    MemoryBufferRef Buffer = **BufferOrErr;
    SmallVector<OffloadFile> Binaries;
    if (Error Err = extractOffloadBinaries(Buffer, Binaries))
      return std::move(Err);

    unsigned I = 1;
    for (auto &OffloadFile : Binaries) {
      auto FileNameOrErr = writeOffloadFile(OffloadFile);
      if (!FileNameOrErr)
        return FileNameOrErr.takeError();
      llvm::errs() << I++ << ". " << *FileNameOrErr << "\n";
    }
  }

  return Error::success();
}

} // namespace

int main(int argc, char **argv) {
  InitLLVM X(argc, argv);
  InitializeAllTargetInfos();
  InitializeAllTargets();
  InitializeAllTargetMCs();
  InitializeAllAsmParsers();
  InitializeAllAsmPrinters();

  Executable = argv[0];
  sys::PrintStackTraceOnErrorSignal(argv[0]);

  const OptTable &Tbl = getOptTable();
  BumpPtrAllocator Alloc;
  StringSaver Saver(Alloc);
  auto Args = Tbl.parseArgs(argc, argv, OPT_INVALID, Saver, [&](StringRef Err) {
    reportError(createStringError(inconvertibleErrorCode(), Err));
  });

  if (Args.hasArg(OPT_help) || Args.hasArg(OPT_help_hidden)) {
    Tbl.printHelp(
        outs(), "clang-sycl-linker [options] <options to sycl link steps>",
        "A utility that wraps around several steps required to link SYCL "
        "device files.\n"
        "This enables LLVM IR linking, post-linking and code generation for "
        "SYCL targets.",
        Args.hasArg(OPT_help_hidden), Args.hasArg(OPT_help_hidden));
    return EXIT_SUCCESS;
  }

  if (Args.hasArg(OPT_version))
    printVersion(outs());

  Verbose = Args.hasArg(OPT_verbose);
  DryRun = Args.hasArg(OPT_dry_run);
  SaveTemps = Args.hasArg(OPT_save_temps);

  OutputFile = "a.spv";
  if (Args.hasArg(OPT_o))
    OutputFile = Args.getLastArgValue(OPT_o);

  if (Args.hasArg(OPT_spirv_dump_device_code_EQ)) {
    Arg *A = Args.getLastArg(OPT_spirv_dump_device_code_EQ);
    SmallString<128> Dir(A->getValue());
    if (Dir.empty())
      llvm::sys::path::native(Dir = "./");
    else
      Dir.append(llvm::sys::path::get_separator());

    SPIRVDumpDir = Dir;
  }

  // Get the input files to pass to the linking stage.
  auto FilesOrErr = getInput(Args);
  if (!FilesOrErr)
    reportError(FilesOrErr.takeError());

  // Run SYCL linking process on the generated inputs.
  if (Error Err = runSYCLLink(*FilesOrErr, Args))
    reportError(std::move(Err));

  // Remove the temporary files created.
  if (!Args.hasArg(OPT_save_temps))
    for (const auto &TempFile : TempFiles)
      if (std::error_code EC = sys::fs::remove(TempFile))
        reportError(createFileError(TempFile, EC));

  return EXIT_SUCCESS;
}
