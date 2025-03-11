// Tests the driver when linking LLVM IR bitcode files and targeting SPIR-V
// architecture.
//
// Test that -Xlinker options are being passed to clang-sycl-linker.
// RUN: touch %t.bc
// RUN: %clangxx -### --target=spirv64 --sycl-link -Xlinker --library-path=/tmp \
// RUN:   -Xlinker --device-libs=lib1.bc,lib2.bc %t.bc 2>&1 \
// RUN:   | FileCheck %s -check-prefix=XLINKEROPTS
// XLINKEROPTS: "{{.*}}clang-sycl-linker{{.*}}" "--library-path=/tmp" "--device-libs=lib1.bc,lib2.bc" "{{.*}}.bc" "-o" "a.out"
