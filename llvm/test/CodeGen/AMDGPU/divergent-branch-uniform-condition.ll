; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py

; NOTE: The checks for opt are NOT added by the update script. Those
;       checks are looking for the absence of specific metadata, which
;       cannot be expressed reliably by the generated checks.

; RUN: llc -mtriple=amdgcn -mcpu=gfx900 < %s | FileCheck %s -check-prefix=ISA
; RUN: opt --amdgpu-annotate-uniform -S %s |  FileCheck %s -check-prefix=UNIFORM
; RUN: opt --amdgpu-annotate-uniform --si-annotate-control-flow -S %s |  FileCheck %s -check-prefix=CONTROLFLOW

; This module creates a divergent branch in block Flow2. The branch is
; marked as divergent by the divergence analysis but the condition is
; not. This test ensures that the divergence of the branch is tested,
; not its condition, so that branch is correctly emitted as divergent.

target triple = "amdgcn-mesa-mesa3d"

define amdgpu_ps void @main(i32 %0, float %1) {
; ISA-LABEL: main:
; ISA:       ; %bb.0: ; %start
; ISA-NEXT:    v_readfirstlane_b32 s0, v0
; ISA-NEXT:    s_mov_b32 m0, s0
; ISA-NEXT:    s_mov_b32 s10, 0
; ISA-NEXT:    v_interp_p1_f32_e32 v0, v1, attr0.x
; ISA-NEXT:    v_cmp_nlt_f32_e32 vcc, 0, v0
; ISA-NEXT:    s_mov_b64 s[0:1], 0
; ISA-NEXT:    ; implicit-def: $sgpr4_sgpr5
; ISA-NEXT:    ; implicit-def: $sgpr2_sgpr3
; ISA-NEXT:    s_branch .LBB0_3
; ISA-NEXT:  .LBB0_1: ; %Flow1
; ISA-NEXT:    ; in Loop: Header=BB0_3 Depth=1
; ISA-NEXT:    s_or_b64 exec, exec, s[4:5]
; ISA-NEXT:    s_mov_b64 s[8:9], 0
; ISA-NEXT:    s_mov_b64 s[4:5], s[6:7]
; ISA-NEXT:  .LBB0_2: ; %Flow
; ISA-NEXT:    ; in Loop: Header=BB0_3 Depth=1
; ISA-NEXT:    s_and_b64 s[6:7], exec, s[4:5]
; ISA-NEXT:    s_or_b64 s[0:1], s[6:7], s[0:1]
; ISA-NEXT:    s_andn2_b64 s[2:3], s[2:3], exec
; ISA-NEXT:    s_and_b64 s[6:7], s[8:9], exec
; ISA-NEXT:    s_or_b64 s[2:3], s[2:3], s[6:7]
; ISA-NEXT:    s_andn2_b64 exec, exec, s[0:1]
; ISA-NEXT:    s_cbranch_execz .LBB0_6
; ISA-NEXT:  .LBB0_3: ; %loop
; ISA-NEXT:    ; =>This Inner Loop Header: Depth=1
; ISA-NEXT:    s_or_b64 s[4:5], s[4:5], exec
; ISA-NEXT:    s_mov_b64 s[6:7], -1
; ISA-NEXT:    s_cmp_lt_u32 s10, 32
; ISA-NEXT:    s_mov_b64 s[8:9], -1
; ISA-NEXT:    s_cbranch_scc0 .LBB0_2
; ISA-NEXT:  ; %bb.4: ; %endif1
; ISA-NEXT:    ; in Loop: Header=BB0_3 Depth=1
; ISA-NEXT:    s_and_saveexec_b64 s[4:5], vcc
; ISA-NEXT:    s_cbranch_execz .LBB0_1
; ISA-NEXT:  ; %bb.5: ; %endif2
; ISA-NEXT:    ; in Loop: Header=BB0_3 Depth=1
; ISA-NEXT:    s_add_i32 s10, s10, 1
; ISA-NEXT:    s_xor_b64 s[6:7], exec, -1
; ISA-NEXT:    s_branch .LBB0_1
; ISA-NEXT:  .LBB0_6: ; %Flow2
; ISA-NEXT:    s_or_b64 exec, exec, s[0:1]
; ISA-NEXT:    v_mov_b32_e32 v1, 0
; ISA-NEXT:    s_and_saveexec_b64 s[0:1], s[2:3]
; ISA-NEXT:  ; %bb.7: ; %if1
; ISA-NEXT:    v_sqrt_f32_e32 v1, v0
; ISA-NEXT:  ; %bb.8: ; %endloop
; ISA-NEXT:    s_or_b64 exec, exec, s[0:1]
; ISA-NEXT:    exp mrt0 v1, v1, v1, v1 done vm
; ISA-NEXT:    s_endpgm
start:
  %v0 = call float @llvm.amdgcn.interp.p1(float %1, i32 0, i32 0, i32 %0)
  br label %loop

loop:                                             ; preds = %Flow, %start
  %v1 = phi i32 [ 0, %start ], [ %6, %Flow ]
  %v2 = icmp ugt i32 %v1, 31
  %2 = xor i1 %v2, true
  br i1 %2, label %endif1, label %Flow

Flow1:                                            ; preds = %endif2, %endif1
  %3 = phi i32 [ %v5, %endif2 ], [ poison, %endif1 ]
  %4 = phi i1 [ false, %endif2 ], [ true, %endif1 ]
  br label %Flow

; UNIFORM-LABEL: Flow2:
; UNIFORM-NEXT: br i1 %8, label %if1, label %endloop
; UNIFORM-NOT: !amdgpu.uniform
; UNIFORM: if1:

; CONTROLFLOW-LABEL: Flow2:
; CONTROLFLOW-NEXT:  call void @llvm.amdgcn.end.cf.i64(i64 %{{.*}})
; CONTROLFLOW-NEXT:  [[IF:%.*]] = call { i1, i64 } @llvm.amdgcn.if.i64(i1 %{{.*}})
; CONTROLFLOW-NEXT:  [[COND:%.*]] = extractvalue { i1, i64 } [[IF]], 0
; CONTROLFLOW-NEXT:  %{{.*}} = extractvalue { i1, i64 } [[IF]], 1
; CONTROLFLOW-NEXT:  br i1 [[COND]], label %if1, label %endloop

Flow2:                                            ; preds = %Flow
  br i1 %8, label %if1, label %endloop

if1:                                              ; preds = %Flow2
  %v3 = call afn float @llvm.sqrt.f32(float %v0)
  br label %endloop

endif1:                                           ; preds = %loop
  %v4 = fcmp ogt float %v0, 0.000000e+00
  %5 = xor i1 %v4, true
  br i1 %5, label %endif2, label %Flow1

Flow:                                             ; preds = %Flow1, %loop
  %6 = phi i32 [ %3, %Flow1 ], [ poison, %loop ]
  %7 = phi i1 [ %4, %Flow1 ], [ true, %loop ]
  %8 = phi i1 [ false, %Flow1 ], [ true, %loop ]
  br i1 %7, label %Flow2, label %loop

endif2:                                           ; preds = %endif1
  %v5 = add i32 %v1, 1
  br label %Flow1

endloop:                                          ; preds = %if1, %Flow2
  %v6 = phi float [ 0.000000e+00, %Flow2 ], [ %v3, %if1 ]
  call void @llvm.amdgcn.exp.f32(i32 0, i32 15, float %v6, float %v6, float %v6, float %v6, i1 true, i1 true)
  ret void
}

define amdgpu_ps void @i1_copy_assert(i1 %v4) {
; ISA-LABEL: i1_copy_assert:
; ISA:       ; %bb.0: ; %start
; ISA-NEXT:    v_and_b32_e32 v0, 1, v0
; ISA-NEXT:    v_cmp_eq_u32_e32 vcc, 1, v0
; ISA-NEXT:    s_mov_b32 s8, 0
; ISA-NEXT:    s_mov_b64 s[0:1], 0
; ISA-NEXT:    ; implicit-def: $sgpr4_sgpr5
; ISA-NEXT:    ; implicit-def: $sgpr2_sgpr3
; ISA-NEXT:    s_branch .LBB1_3
; ISA-NEXT:  .LBB1_1: ; %endif1
; ISA-NEXT:    ; in Loop: Header=BB1_3 Depth=1
; ISA-NEXT:    s_andn2_b64 s[4:5], s[4:5], exec
; ISA-NEXT:    s_and_b64 s[8:9], vcc, exec
; ISA-NEXT:    s_mov_b64 s[6:7], 0
; ISA-NEXT:    s_or_b64 s[4:5], s[4:5], s[8:9]
; ISA-NEXT:  .LBB1_2: ; %Flow
; ISA-NEXT:    ; in Loop: Header=BB1_3 Depth=1
; ISA-NEXT:    s_and_b64 s[8:9], exec, s[4:5]
; ISA-NEXT:    s_or_b64 s[0:1], s[8:9], s[0:1]
; ISA-NEXT:    s_andn2_b64 s[2:3], s[2:3], exec
; ISA-NEXT:    s_and_b64 s[6:7], s[6:7], exec
; ISA-NEXT:    s_mov_b32 s8, 1
; ISA-NEXT:    s_or_b64 s[2:3], s[2:3], s[6:7]
; ISA-NEXT:    s_andn2_b64 exec, exec, s[0:1]
; ISA-NEXT:    s_cbranch_execz .LBB1_5
; ISA-NEXT:  .LBB1_3: ; %loop
; ISA-NEXT:    ; =>This Inner Loop Header: Depth=1
; ISA-NEXT:    s_or_b64 s[4:5], s[4:5], exec
; ISA-NEXT:    s_cmp_lg_u32 s8, 0
; ISA-NEXT:    s_cbranch_scc1 .LBB1_1
; ISA-NEXT:  ; %bb.4: ; in Loop: Header=BB1_3 Depth=1
; ISA-NEXT:    s_mov_b64 s[6:7], -1
; ISA-NEXT:    s_branch .LBB1_2
; ISA-NEXT:  .LBB1_5: ; %Flow2
; ISA-NEXT:    s_or_b64 exec, exec, s[0:1]
; ISA-NEXT:    v_mov_b32_e32 v0, 0
; ISA-NEXT:    v_cndmask_b32_e64 v1, 0, 1.0, s[2:3]
; ISA-NEXT:    exp mrt0 off, off, off, off
; ISA-NEXT:    s_endpgm
start:
  br label %loop

loop:                                             ; preds = %Flow, %start
  %v1 = phi i32 [ 0, %start ], [ 1, %Flow ]
  %v2 = icmp ugt i32 %v1, 0
  br i1 %v2, label %endif1, label %Flow

Flow2:                                            ; preds = %Flow
  %spec.select = select i1 %i1, float 1.000000e+00, float 0.000000e+00
  call void @llvm.amdgcn.exp.f32(i32 0, i32 0, float %spec.select, float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, i1 false, i1 false)
  ret void

endif1:                                           ; preds = %loop
  br label %Flow

Flow:                                             ; preds = %endif1, %loop
  %i = phi i1 [ %v4, %endif1 ], [ true, %loop ]
  %i1 = phi i1 [ false, %endif1 ], [ true, %loop ]
  br i1 %i, label %Flow2, label %loop
}

; Function Attrs: nounwind readnone speculatable willreturn
declare float @llvm.sqrt.f32(float) #0

; Function Attrs: nounwind readnone speculatable
declare float @llvm.amdgcn.interp.p1(float, i32 immarg, i32 immarg, i32) #1

; Function Attrs: inaccessiblememonly nounwind writeonly
declare void @llvm.amdgcn.exp.f32(i32 immarg, i32 immarg, float, float, float, float, i1 immarg, i1 immarg) #2

attributes #0 = { nounwind readnone speculatable willreturn }
attributes #1 = { nounwind readnone speculatable }
attributes #2 = { inaccessiblememonly nounwind writeonly }
