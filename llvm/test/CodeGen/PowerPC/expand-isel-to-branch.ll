; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 4
; RUN: llc -verify-machineinstrs -mtriple=powerpc64-ibm-aix < %s | FileCheck %s

define noundef signext i32 @ham(ptr nocapture noundef %arg) #0 {
; CHECK-LABEL: ham:
; CHECK:       # %bb.0: # %bb
; CHECK-NEXT:    lwz 4, 0(3)
; CHECK-NEXT:    cmpwi 4, 750
; CHECK-NEXT:    blt 0, L..BB0_2
; CHECK-NEXT:  # %bb.1: # %bb
; CHECK-NEXT:    li 4, 1
; CHECK-NEXT:    b L..BB0_3
; CHECK-NEXT:  L..BB0_2:
; CHECK-NEXT:    addi 4, 4, 1
; CHECK-NEXT:  L..BB0_3: # %bb
; CHECK-NEXT:    stw 4, 0(3)
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:    blr
bb:
  %load = load i32, ptr %arg, align 4
  %icmp = icmp slt i32 %load, 750
  %add = add nsw i32 %load, 1
  %select = select i1 %icmp, i32 %add, i32 1
  store i32 %select, ptr %arg, align 4
  ret i32 0
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="pwr8" "target-features"="+altivec,+bpermd,+crbits,+crypto,+direct-move,+extdiv,+htm,+isa-v206-instructions,+isa-v207-instructions,+power8-vector,+quadword-atomics,+vsx,-aix-small-local-exec-tls,-isa-v30-instructions,-isel,-power9-vector,-privileged,-rop-protect,-spe" }
