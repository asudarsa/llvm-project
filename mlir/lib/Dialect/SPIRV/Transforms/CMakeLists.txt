set(LLVM_OPTIONAL_SOURCES
  CanonicalizeGLPass.cpp
  ConvertToReplicatedConstantCompositePass.cpp
  DecorateCompositeTypeLayoutPass.cpp
  LowerABIAttributesPass.cpp
  RewriteInsertsPass.cpp
  SPIRVConversion.cpp
  SPIRVWebGPUTransforms.cpp
  UnifyAliasedResourcePass.cpp
  UpdateVCEPass.cpp
)

add_mlir_dialect_library(MLIRSPIRVConversion
  SPIRVConversion.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/SPIRV

  LINK_LIBS PUBLIC
  MLIRArithDialect
  MLIRDialectUtils
  MLIRFuncDialect
  MLIRIR
  MLIRPass
  MLIRSPIRVDialect
  MLIRSupport
  MLIRTransformUtils
  MLIRVectorDialect
  MLIRVectorTransforms
)

add_mlir_dialect_library(MLIRSPIRVTransforms
  CanonicalizeGLPass.cpp
  ConvertToReplicatedConstantCompositePass.cpp
  DecorateCompositeTypeLayoutPass.cpp
  LowerABIAttributesPass.cpp
  RewriteInsertsPass.cpp
  SPIRVWebGPUTransforms.cpp
  UnifyAliasedResourcePass.cpp
  UpdateVCEPass.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/SPIRV

  DEPENDS
  MLIRSPIRVPassIncGen

  LINK_LIBS PUBLIC
  MLIRPass
  MLIRSPIRVConversion
  MLIRSPIRVUtils
)
