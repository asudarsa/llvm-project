//===- OptimizeSharedMemory.cpp - MLIR NVGPU pass implementation ----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements transforms to enable 1xtf32 and 3xtf32 nvgpu.mma sync
// operations on f32 input datatype
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/NVGPU/Transforms/Transforms.h"

#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/NVGPU/IR/NVGPUDialect.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"

using namespace mlir;
using namespace mlir::nvgpu;

namespace {

struct MmaSyncF32ToTF32Pattern : public OpRewritePattern<nvgpu::MmaSyncOp> {

  using OpRewritePattern<nvgpu::MmaSyncOp>::OpRewritePattern;

  MmaSyncF32ToTF32Pattern(MLIRContext *context,
                          nvgpu::MmaSyncF32Lowering precision)
      : OpRewritePattern<nvgpu::MmaSyncOp>(context, /*benifit*/ 1),
        precision(precision) {}

  LogicalResult matchAndRewrite(nvgpu::MmaSyncOp op,
                                PatternRewriter &rewriter) const override {
    Location location = op->getLoc();

    if (op->hasAttr(op.getTf32EnabledAttrName()) ||
        !cast<VectorType>(op.getMatrixA().getType()).getElementType().isF32())
      return failure();

    if (precision == MmaSyncF32Lowering::Unkown)
      return emitError(location, "MmaSync F32-to-TF32 cannot be lowered with "
                                 "unknown precision level");

    if (precision == MmaSyncF32Lowering::TF32x3)
      return emitError(location, "TF32x3 is not supported at the moment "
                                 "for nvgpu.mma.sync on f32 datatype");

    if (precision == MmaSyncF32Lowering::TF32) {
      rewriter.modifyOpInPlace(
          op, [&]() { op.setTf32EnabledAttr(rewriter.getUnitAttr()); });
    }

    return success();
  }

private:
  /// Precision for F32 Tensor Cores (TF32 or TF32x3)
  nvgpu::MmaSyncF32Lowering precision;
};

} // namespace

void mlir::nvgpu::populateMmaSyncF32ToTF32Patterns(
    RewritePatternSet &patterns, nvgpu::MmaSyncF32Lowering precision) {

  patterns.add<MmaSyncF32ToTF32Pattern>(patterns.getContext(), precision);
}
