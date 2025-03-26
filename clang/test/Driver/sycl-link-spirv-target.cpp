// Tests the driver when linking LLVM IR bitcode files and targeting SPIR-V
// architecture.
//
// Test that -Xlinker options are being passed to clang-sycl-linker.
// RUN: touch %t.o
// RUN: %clangxx -### --target=spirv64 --sycl-link -Xlinker --llvm-spirv-path=/tmp \
// RUN:   -Xlinker --library-path=/tmp -Xlinker --device-libs=lib1.o,lib2.o %t.o 2>&1 \
// RUN:   | FileCheck %s -check-prefix=XLINKEROPTS
// XLINKEROPTS: "{{.*}}clang-sycl-linker{{.*}}" "--llvm-spirv-path=/tmp" "--library-path=/tmp" "--device-libs=lib1.o,lib2.o" "{{.*}}.o" "-o" "a.out"
