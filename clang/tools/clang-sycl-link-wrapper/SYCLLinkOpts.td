// We try to create options similar to lld's.  That way, options passed to clang
// -Xoffload-linker can be the same whether offloading to nvptx or amdgpu.

include "llvm/Option/OptParser.td"

def WrapperOnlyOption : OptionFlag;

def help : Flag<["-", "--"], "help">,
  HelpText<"Display available options (--help-hidden for more)">;

def help_hidden : Flag<["-", "--"], "help-hidden">,
  HelpText<"Display all available options">;

def verbose : Flag<["-"], "v">, HelpText<"Print verbose information">;
def version : Flag<["--"], "version">,
  HelpText<"Display the version number and exit">;

def o : JoinedOrSeparate<["-"], "o">, MetaVarName<"<path>">,
  HelpText<"Path to file to write output">;
def output : Separate<["--"], "output-file">, Alias<o>, Flags<[HelpHidden]>,
  HelpText<"Alias for -o">;

def library_path_EQ : Joined<["--", "-"], "library-path=">,
  Flags<[HelpHidden]>, HelpText<"Add <dir> to the library search path">;

def triple : Joined<["--"], "triple">,
  HelpText<"The device target triple">;
def arch : Separate<["--", "-"], "arch">,
  HelpText<"Specify the name of the target architecture.">;

def g : Flag<["-"], "g">, HelpText<"Specify that this was a debug compile.">;
def debug : Flag<["--"], "debug">, Alias<g>;

def save_temps : Flag<["--", "-"], "save-temps">,
  Flags<[WrapperOnlyOption]>, HelpText<"Save intermediate results">;

def dry_run : Flag<["--", "-"], "dry-run">, Flags<[WrapperOnlyOption]>,
  HelpText<"Print generated commands without running.">;

def sycl_dump_device_code_EQ : Joined<["--", "-"], "sycl-dump-device-code=">,
  Flags<[WrapperOnlyOption]>,
  HelpText<"Path to the folder where the tool dumps SPIR-V device code. Other formats aren't dumped.">;

def sycl_is_windows_msvc_env : Flag<["--", "-"], "sycl-is-windows-msvc-env">,
  Flags<[WrapperOnlyOption, HelpHidden]>;

// Special option to pass in llvm-spirv options
def llvm_spirv_options_EQ : Joined<["--", "-"], "llvm-spirv-options=">,
  Flags<[WrapperOnlyOption]>,
  HelpText<"Options that will control llvm-spirv step">;
