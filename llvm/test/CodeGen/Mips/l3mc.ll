; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___fixunsdfsi

; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___floatdidf

; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___floatdisf

; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___floatundidf

; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___fixsfdi

; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___fixunsdfdi

; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___fixdfdi

; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___fixunssfsi

; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___fixunssfdi

; RUN: llc -mtriple=mipsel-linux-gnu -mattr=mips16 -mattr=+soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=__call_stub_fp___floatundisf

@ll1 = global i64 0, align 8
@ll2 = global i64 0, align 8
@ll3 = global i64 0, align 8
@l1 = global i32 0, align 4
@l2 = global i32 0, align 4
@l3 = global i32 0, align 4
@ull1 = global i64 0, align 8
@ull2 = global i64 0, align 8
@ull3 = global i64 0, align 8
@ul1 = global i32 0, align 4
@ul2 = global i32 0, align 4
@ul3 = global i32 0, align 4
@d1 = global double 0.000000e+00, align 8
@d2 = global double 0.000000e+00, align 8
@d3 = global double 0.000000e+00, align 8
@d4 = global double 0.000000e+00, align 8
@f1 = global float 0.000000e+00, align 4
@f2 = global float 0.000000e+00, align 4
@f3 = global float 0.000000e+00, align 4
@f4 = global float 0.000000e+00, align 4

; Function Attrs: nounwind
define void @_Z3foov() #0 {
entry:
  %0 = load double, ptr @d1, align 8
  %conv = fptosi double %0 to i64
  store i64 %conv, ptr @ll1, align 8
  %1 = load double, ptr @d2, align 8
  %conv1 = fptoui double %1 to i64
  store i64 %conv1, ptr @ull1, align 8
  %2 = load float, ptr @f1, align 4
  %conv2 = fptosi float %2 to i64
  store i64 %conv2, ptr @ll2, align 8
  %3 = load float, ptr @f2, align 4
  %conv3 = fptoui float %3 to i64
  store i64 %conv3, ptr @ull2, align 8
  %4 = load double, ptr @d3, align 8
  %conv4 = fptosi double %4 to i32
  store i32 %conv4, ptr @l1, align 4
  %5 = load double, ptr @d4, align 8
  %conv5 = fptoui double %5 to i32
  store i32 %conv5, ptr @ul1, align 4
  %6 = load float, ptr @f3, align 4
  %conv6 = fptosi float %6 to i32
  store i32 %conv6, ptr @l2, align 4
  %7 = load float, ptr @f4, align 4
  %conv7 = fptoui float %7 to i32
  store i32 %conv7, ptr @ul2, align 4
  ret void
}

; Function Attrs: nounwind
define void @_Z3goov() #0 {
entry:
  %0 = load i64, ptr @ll1, align 8
  %conv = sitofp i64 %0 to double
  store double %conv, ptr @d1, align 8
  %1 = load i64, ptr @ull1, align 8
  %conv1 = uitofp i64 %1 to double
  store double %conv1, ptr @d2, align 8
  %2 = load i64, ptr @ll2, align 8
  %conv2 = sitofp i64 %2 to float
  store float %conv2, ptr @f1, align 4
  %3 = load i64, ptr @ull2, align 8
  %conv3 = uitofp i64 %3 to float
  store float %conv3, ptr @f2, align 4
  %4 = load i32, ptr @l1, align 4
  %conv4 = sitofp i32 %4 to double
  store double %conv4, ptr @d3, align 8
  %5 = load i32, ptr @ul1, align 4
  %conv5 = uitofp i32 %5 to double
  store double %conv5, ptr @d4, align 8
  %6 = load i32, ptr @l2, align 4
  %conv6 = sitofp i32 %6 to float
  store float %conv6, ptr @f3, align 4
  %7 = load i32, ptr @ul2, align 4
  %conv7 = uitofp i32 %7 to float
  store float %conv7, ptr @f4, align 4
  ret void
}

attributes #0 = { nounwind "less-precise-fpmad"="false" "frame-pointer"="all" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

; __call_stub_fp___fixunsdfsi:  __call_stub_fp___fixunsdfsi:
; __call_stub_fp___floatdidf:  __call_stub_fp___floatdidf:
; __call_stub_fp___floatdisf:  __call_stub_fp___floatdisf:
; __call_stub_fp___floatundidf:  __call_stub_fp___floatundidf:
; __call_stub_fp___fixsfdi:  __call_stub_fp___fixsfdi:
; __call_stub_fp___fixunsdfdi:  __call_stub_fp___fixunsdfdi:
; __call_stub_fp___fixdfdi:  __call_stub_fp___fixdfdi:
; __call_stub_fp___fixunssfsi:  __call_stub_fp___fixunssfsi:
; __call_stub_fp___fixunssfdi:  __call_stub_fp___fixunssfdi:
; __call_stub_fp___floatundisf:  __call_stub_fp___floatundisf:

