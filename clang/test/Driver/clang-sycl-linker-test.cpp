// Tests the clang-sycl-linker tool.
//
// Test a simple case without arguments.
// RUN: %clangxx -emit-llvm -c %s -o %t_1.bc
// RUN: %clangxx -emit-llvm -c %s -o %t_2.bc
// RUN: clang-sycl-linker --dry-run -v %t_1.bc %t_2.bc -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=SIMPLE
// SIMPLE: "{{.*}}llvm-link{{.*}}" {{.*}}.bc {{.*}}.bc -o [[FIRSTLLVMLINKOUT:.*]].bc --suppress-warnings
// SIMPLE-NEXT: SPIR-V Backend: input: {{.*}}.bc, output: a.spv
//
// Test that llvm-link is not called when only one input is present.
// RUN: clang-sycl-linker --dry-run -v %t_1.bc -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=SIMPLE-NO-LINK
// SIMPLE-NO-LINK: SPIR-V Backend: input: {{.*}}.bc, output: a.spv
//
// Test a simple case with device library files specified.
// RUN: touch %T/lib1.bc
// RUN: touch %T/lib2.bc
// RUN: clang-sycl-linker --dry-run -v %t_1.bc %t_2.bc --library-path=%T --device-libs=lib1.bc,lib2.bc -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=DEVLIBS
// DEVLIBS: "{{.*}}llvm-link{{.*}}" {{.*}}.bc {{.*}}.bc -o [[FIRSTLLVMLINKOUT:.*]].bc --suppress-warnings
// DEVLIBS-NEXT: "{{.*}}llvm-link{{.*}}" -only-needed [[FIRSTLLVMLINKOUT]].bc {{.*}}lib1.bc {{.*}}lib2.bc -o [[SECONDLLVMLINKOUT:.*]].bc --suppress-warnings
// DEVLIBS-NEXT: SPIR-V Backend: input: [[SECONDLLVMLINKOUT]].bc, output: a.spv
//
// Test a simple case with .o (fat object) as input.
// TODO: Remove this test once fat object support is added.
// RUN: %clangxx -c %s -o %t.o
// RUN: not clang-sycl-linker --dry-run -v %t.o -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=FILETYPEERROR
// FILETYPEERROR: Unsupported file type
//
// Test to see if device library related errors are emitted.
// RUN: not clang-sycl-linker --dry-run %t_1.bc %t_2.bc --library-path=%T --device-libs= -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=DEVLIBSERR1
// DEVLIBSERR1: Number of device library files cannot be zero
// RUN: not clang-sycl-linker --dry-run %t_1.bc %t_2.bc --library-path=%T --device-libs=lib1.bc,lib2.bc,lib3.bc -o a.spv 2>&1 \
// RUN:   | FileCheck %s --check-prefix=DEVLIBSERR2
// DEVLIBSERR2: '{{.*}}lib3.bc' SYCL device library file is not found
