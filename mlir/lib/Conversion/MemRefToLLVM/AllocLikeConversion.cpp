//===- AllocLikeConversion.cpp - LLVM conversion for alloc operations -----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/MemRefToLLVM/AllocLikeConversion.h"
#include "mlir/Analysis/DataLayoutAnalysis.h"
#include "mlir/Dialect/LLVMIR/FunctionCallUtils.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/IR/SymbolTable.h"

using namespace mlir;

static FailureOr<LLVM::LLVMFuncOp>
getNotalignedAllocFn(const LLVMTypeConverter *typeConverter, Operation *module,
                     Type indexType) {
  bool useGenericFn = typeConverter->getOptions().useGenericFunctions;
  if (useGenericFn)
    return LLVM::lookupOrCreateGenericAllocFn(module, indexType);

  return LLVM::lookupOrCreateMallocFn(module, indexType);
}

static FailureOr<LLVM::LLVMFuncOp>
getAlignedAllocFn(const LLVMTypeConverter *typeConverter, Operation *module,
                  Type indexType) {
  bool useGenericFn = typeConverter->getOptions().useGenericFunctions;

  if (useGenericFn)
    return LLVM::lookupOrCreateGenericAlignedAllocFn(module, indexType);

  return LLVM::lookupOrCreateAlignedAllocFn(module, indexType);
}

Value AllocationOpLLVMLowering::createAligned(
    ConversionPatternRewriter &rewriter, Location loc, Value input,
    Value alignment) {
  Value one = createIndexAttrConstant(rewriter, loc, alignment.getType(), 1);
  Value bump = rewriter.create<LLVM::SubOp>(loc, alignment, one);
  Value bumped = rewriter.create<LLVM::AddOp>(loc, input, bump);
  Value mod = rewriter.create<LLVM::URemOp>(loc, bumped, alignment);
  return rewriter.create<LLVM::SubOp>(loc, bumped, mod);
}

static Value castAllocFuncResult(ConversionPatternRewriter &rewriter,
                                 Location loc, Value allocatedPtr,
                                 MemRefType memRefType, Type elementPtrType,
                                 const LLVMTypeConverter &typeConverter) {
  auto allocatedPtrTy = cast<LLVM::LLVMPointerType>(allocatedPtr.getType());
  FailureOr<unsigned> maybeMemrefAddrSpace =
      typeConverter.getMemRefAddressSpace(memRefType);
  if (failed(maybeMemrefAddrSpace))
    return Value();
  unsigned memrefAddrSpace = *maybeMemrefAddrSpace;
  if (allocatedPtrTy.getAddressSpace() != memrefAddrSpace)
    allocatedPtr = rewriter.create<LLVM::AddrSpaceCastOp>(
        loc, LLVM::LLVMPointerType::get(rewriter.getContext(), memrefAddrSpace),
        allocatedPtr);
  return allocatedPtr;
}

std::tuple<Value, Value> AllocationOpLLVMLowering::allocateBufferManuallyAlign(
    ConversionPatternRewriter &rewriter, Location loc, Value sizeBytes,
    Operation *op, Value alignment) const {
  if (alignment) {
    // Adjust the allocation size to consider alignment.
    sizeBytes = rewriter.create<LLVM::AddOp>(loc, sizeBytes, alignment);
  }

  MemRefType memRefType = getMemRefResultType(op);
  // Allocate the underlying buffer.
  Type elementPtrType = this->getElementPtrType(memRefType);
  assert(elementPtrType && "could not compute element ptr type");
  FailureOr<LLVM::LLVMFuncOp> allocFuncOp = getNotalignedAllocFn(
      getTypeConverter(), op->getParentWithTrait<OpTrait::SymbolTable>(),
      getIndexType());
  if (failed(allocFuncOp))
    return std::make_tuple(Value(), Value());
  auto results =
      rewriter.create<LLVM::CallOp>(loc, allocFuncOp.value(), sizeBytes);

  Value allocatedPtr =
      castAllocFuncResult(rewriter, loc, results.getResult(), memRefType,
                          elementPtrType, *getTypeConverter());
  if (!allocatedPtr)
    return std::make_tuple(Value(), Value());
  Value alignedPtr = allocatedPtr;
  if (alignment) {
    // Compute the aligned pointer.
    Value allocatedInt =
        rewriter.create<LLVM::PtrToIntOp>(loc, getIndexType(), allocatedPtr);
    Value alignmentInt = createAligned(rewriter, loc, allocatedInt, alignment);
    alignedPtr =
        rewriter.create<LLVM::IntToPtrOp>(loc, elementPtrType, alignmentInt);
  }

  return std::make_tuple(allocatedPtr, alignedPtr);
}

unsigned AllocationOpLLVMLowering::getMemRefEltSizeInBytes(
    MemRefType memRefType, Operation *op,
    const DataLayout *defaultLayout) const {
  const DataLayout *layout = defaultLayout;
  if (const DataLayoutAnalysis *analysis =
          getTypeConverter()->getDataLayoutAnalysis()) {
    layout = &analysis->getAbove(op);
  }
  Type elementType = memRefType.getElementType();
  if (auto memRefElementType = dyn_cast<MemRefType>(elementType))
    return getTypeConverter()->getMemRefDescriptorSize(memRefElementType,
                                                       *layout);
  if (auto memRefElementType = dyn_cast<UnrankedMemRefType>(elementType))
    return getTypeConverter()->getUnrankedMemRefDescriptorSize(
        memRefElementType, *layout);
  return layout->getTypeSize(elementType);
}

bool AllocationOpLLVMLowering::isMemRefSizeMultipleOf(
    MemRefType type, uint64_t factor, Operation *op,
    const DataLayout *defaultLayout) const {
  uint64_t sizeDivisor = getMemRefEltSizeInBytes(type, op, defaultLayout);
  for (unsigned i = 0, e = type.getRank(); i < e; i++) {
    if (type.isDynamicDim(i))
      continue;
    sizeDivisor = sizeDivisor * type.getDimSize(i);
  }
  return sizeDivisor % factor == 0;
}

Value AllocationOpLLVMLowering::allocateBufferAutoAlign(
    ConversionPatternRewriter &rewriter, Location loc, Value sizeBytes,
    Operation *op, const DataLayout *defaultLayout, int64_t alignment) const {
  Value allocAlignment =
      createIndexAttrConstant(rewriter, loc, getIndexType(), alignment);

  MemRefType memRefType = getMemRefResultType(op);
  // Function aligned_alloc requires size to be a multiple of alignment; we pad
  // the size to the next multiple if necessary.
  if (!isMemRefSizeMultipleOf(memRefType, alignment, op, defaultLayout))
    sizeBytes = createAligned(rewriter, loc, sizeBytes, allocAlignment);

  Type elementPtrType = this->getElementPtrType(memRefType);
  FailureOr<LLVM::LLVMFuncOp> allocFuncOp = getAlignedAllocFn(
      getTypeConverter(), op->getParentWithTrait<OpTrait::SymbolTable>(),
      getIndexType());
  if (failed(allocFuncOp))
    return Value();
  auto results = rewriter.create<LLVM::CallOp>(
      loc, allocFuncOp.value(), ValueRange({allocAlignment, sizeBytes}));

  return castAllocFuncResult(rewriter, loc, results.getResult(), memRefType,
                             elementPtrType, *getTypeConverter());
}

void AllocLikeOpLLVMLowering::setRequiresNumElements() {
  requiresNumElements = true;
}

LogicalResult AllocLikeOpLLVMLowering::matchAndRewrite(
    Operation *op, ArrayRef<Value> operands,
    ConversionPatternRewriter &rewriter) const {
  MemRefType memRefType = getMemRefResultType(op);
  if (!isConvertibleAndHasIdentityMaps(memRefType))
    return rewriter.notifyMatchFailure(op, "incompatible memref type");
  auto loc = op->getLoc();

  // Get actual sizes of the memref as values: static sizes are constant
  // values and dynamic sizes are passed to 'alloc' as operands.  In case of
  // zero-dimensional memref, assume a scalar (size 1).
  SmallVector<Value, 4> sizes;
  SmallVector<Value, 4> strides;
  Value size;

  this->getMemRefDescriptorSizes(loc, memRefType, operands, rewriter, sizes,
                                 strides, size, !requiresNumElements);

  // Allocate the underlying buffer.
  auto [allocatedPtr, alignedPtr] =
      this->allocateBuffer(rewriter, loc, size, op);

  if (!allocatedPtr || !alignedPtr)
    return rewriter.notifyMatchFailure(loc,
                                       "underlying buffer allocation failed");

  // Create the MemRef descriptor.
  auto memRefDescriptor = this->createMemRefDescriptor(
      loc, memRefType, allocatedPtr, alignedPtr, sizes, strides, rewriter);

  // Return the final value of the descriptor.
  rewriter.replaceOp(op, {memRefDescriptor});
  return success();
}
