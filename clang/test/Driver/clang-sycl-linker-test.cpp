// Tests the clang-sycl-linker tool.
//
// Test a simple case to link two input files.
// RUN: touch %t_1.o
// RUN: touch %t_2.o
// RUN: clang-sycl-linker --dry-run -triple spirv64 %t_1.o %t_2.o -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=SIMPLE-FO
// SIMPLE-FO: sycl-device-link: inputs: {{.*}}.o, {{.*}}.o  libfiles:  output: [[LLVMLINKOUT:.*]].bc
// SIMPLE-FO-NEXT: "{{.*}}llvm-spirv{{.*}}" {{.*}}-o a.spv [[LLVMLINKOUT]].bc
//
// Test a simple case with device library files specified.
// RUN: touch %T/lib1.o
// RUN: touch %T/lib2.o
// RUN: clang-sycl-linker --dry-run -triple spirv64 %t_1.o %t_2.o --library-path=%T --device-libs=lib1.o,lib2.o -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=DEVLIBS
// DEVLIBS: sycl-device-link: inputs: {{.*}}.o  libfiles: {{.*}}lib1.o, {{.*}}lib2.o  output: [[LLVMLINKOUT:.*]].bc
// DEVLIBS-NEXT: "{{.*}}llvm-spirv{{.*}}" {{.*}}-o a.spv [[LLVMLINKOUT]].bc
//
// Test a simple case with a random file (not bitcode) as input.
// RUN: touch %t.x.o
// RUN: clang-offload-packager -o %t.o --image=file=%t.x.o,kind=openmp,triple=spirv64,arch=
// RUN: not clang-sycl-linker -triple spirv64 %t.o -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=FILETYPEERROR
// FILETYPEERROR: Unsupported file type
//
// Test to see if device library related errors are emitted.
// RUN: not clang-sycl-linker --dry-run -triple spirv64 %t_1.bc %t_2.bc --library-path=%T --device-libs= -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=DEVLIBSERR1
// DEVLIBSERR1: Number of device library files cannot be zero
// RUN: not clang-sycl-linker --dry-run -triple spirv64 %t_1.bc %t_2.bc --library-path=%T --device-libs=lib1.o,lib2.o,lib3.o -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=DEVLIBSERR2
// DEVLIBSERR2: '{{.*}}lib3.o' SYCL device library file is not found
//
// Test if correct set of llvm-spirv options are emitted for windows environment.
// RUN: clang-sycl-linker --dry-run -triple spirv64 --is-windows-msvc-env %t_1.bc %t_2.bc -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=LLVMOPTSWIN
// LLVMOPTSWIN: -spirv-debug-info-version=ocl-100 -spirv-allow-extra-diexpressions -spirv-allow-unknown-intrinsics=llvm.genx. -spirv-ext=
//
// Test if correct set of llvm-spirv options are emitted for linux environment.
// RUN: clang-sycl-linker --dry-run -triple spirv64  %t_1.bc %t_2.bc -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=LLVMOPTSLIN
// LLVMOPTSLIN: -spirv-debug-info-version=nonsemantic-shader-200 -spirv-allow-unknown-intrinsics=llvm.genx. -spirv-ext=
