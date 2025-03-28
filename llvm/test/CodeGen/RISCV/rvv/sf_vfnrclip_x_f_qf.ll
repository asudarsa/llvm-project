; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: sed 's/iXLen/i32/g' %s | llc -mtriple=riscv32 -mattr=+v,+xsfvfnrclipxfqf \
; RUN:   -verify-machineinstrs -target-abi=ilp32d | FileCheck %s
; RUN: sed 's/iXLen/i64/g' %s | llc -mtriple=riscv64 -mattr=+v,+xsfvfnrclipxfqf \
; RUN:   -verify-machineinstrs -target-abi=lp64d | FileCheck %s

declare <vscale x 1 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv1i8.nxv1f32.iXLen(
  <vscale x 1 x i8>,
  <vscale x 1 x float>,
  float,
  iXLen, iXLen);

define <vscale x 1 x i8> @intrinsic_sf_vfnrclip_x_f_qf_nxv1i8_nxv1f32(<vscale x 1 x float> %0, float %1, iXLen %2) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_nxv1i8_nxv1f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetvli zero, a0, e8, mf8, ta, ma
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v9, v8, fa0
; CHECK-NEXT:    vmv1r.v v8, v9
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 1 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv1i8.nxv1f32.iXLen(
    <vscale x 1 x i8> undef,
    <vscale x 1 x float> %0,
    float %1,
    iXLen 7, iXLen %2)

  ret <vscale x 1 x i8> %a
}

declare <vscale x 1 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv1i8.nxv1f32.iXLen(
  <vscale x 1 x i8>,
  <vscale x 1 x float>,
  float,
  <vscale x 1 x i1>,
  iXLen, iXLen, iXLen);

define <vscale x 1 x i8> @intrinsic_sf_vfnrclip_x_f_qf_mask_nxv1i8_nxv1f32(<vscale x 1 x i8> %0, <vscale x 1 x float> %1, float %2, <vscale x 1 x i1> %3, iXLen %4) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_mask_nxv1i8_nxv1f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    fsrmi a1, 0
; CHECK-NEXT:    vsetvli zero, a0, e8, mf8, ta, mu
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v8, v9, fa0, v0.t
; CHECK-NEXT:    fsrm a1
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 1 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv1i8.nxv1f32.iXLen(
    <vscale x 1 x i8> %0,
    <vscale x 1 x float> %1,
    float %2,
    <vscale x 1 x i1> %3,
    iXLen 0, iXLen %4, iXLen 1)

  ret <vscale x 1 x i8> %a
}

declare <vscale x 2 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv2i8.nxv2f32.iXLen(
  <vscale x 2 x i8>,
  <vscale x 2 x float>,
  float,
  iXLen, iXLen);

define <vscale x 2 x i8> @intrinsic_sf_vfnrclip_x_f_qf_nxv2i8_nxv2f32(<vscale x 2 x float> %0, float %1, iXLen %2) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_nxv2i8_nxv2f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    fsrmi a1, 0
; CHECK-NEXT:    vsetvli zero, a0, e8, mf4, ta, ma
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v9, v8, fa0
; CHECK-NEXT:    fsrm a1
; CHECK-NEXT:    vmv1r.v v8, v9
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 2 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv2i8.nxv2f32.iXLen(
    <vscale x 2 x i8> undef,
    <vscale x 2 x float> %0,
    float %1,
    iXLen 0, iXLen %2)

  ret <vscale x 2 x i8> %a
}

declare <vscale x 2 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv2i8.nxv2f32.iXLen(
  <vscale x 2 x i8>,
  <vscale x 2 x float>,
  float,
  <vscale x 2 x i1>,
  iXLen, iXLen, iXLen);

define <vscale x 2 x i8> @intrinsic_sf_vfnrclip_x_f_qf_mask_nxv2i8_nxv2f32(<vscale x 2 x i8> %0, <vscale x 2 x float> %1, float %2, <vscale x 2 x i1> %3, iXLen %4) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_mask_nxv2i8_nxv2f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    fsrmi a1, 0
; CHECK-NEXT:    vsetvli zero, a0, e8, mf4, ta, mu
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v8, v9, fa0, v0.t
; CHECK-NEXT:    fsrm a1
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 2 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv2i8.nxv2f32.iXLen(
    <vscale x 2 x i8> %0,
    <vscale x 2 x float> %1,
    float %2,
    <vscale x 2 x i1> %3,
    iXLen 0, iXLen %4, iXLen 1)

  ret <vscale x 2 x i8> %a
}

declare <vscale x 4 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv4i8.nxv4f32.iXLen(
  <vscale x 4 x i8>,
  <vscale x 4 x float>,
  float,
  iXLen, iXLen);

define <vscale x 4 x i8> @intrinsic_sf_vfnrclip_x_f_qf_nxv4i8_nxv4f32(<vscale x 4 x float> %0, float %1, iXLen %2) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_nxv4i8_nxv4f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    fsrmi a1, 0
; CHECK-NEXT:    vsetvli zero, a0, e8, mf2, ta, ma
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v10, v8, fa0
; CHECK-NEXT:    fsrm a1
; CHECK-NEXT:    vmv1r.v v8, v10
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 4 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv4i8.nxv4f32.iXLen(
    <vscale x 4 x i8> undef,
    <vscale x 4 x float> %0,
    float %1,
    iXLen 0, iXLen %2)

  ret <vscale x 4 x i8> %a
}

declare <vscale x 4 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv4i8.nxv4f32.iXLen(
  <vscale x 4 x i8>,
  <vscale x 4 x float>,
  float,
  <vscale x 4 x i1>,
  iXLen, iXLen, iXLen);

define <vscale x 4 x i8> @intrinsic_sf_vfnrclip_x_f_qf_mask_nxv4i8_nxv4f32(<vscale x 4 x i8> %0, <vscale x 4 x float> %1, float %2, <vscale x 4 x i1> %3, iXLen %4) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_mask_nxv4i8_nxv4f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    fsrmi a1, 0
; CHECK-NEXT:    vsetvli zero, a0, e8, mf2, ta, mu
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v8, v10, fa0, v0.t
; CHECK-NEXT:    fsrm a1
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 4 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv4i8.nxv4f32.iXLen(
    <vscale x 4 x i8> %0,
    <vscale x 4 x float> %1,
    float %2,
    <vscale x 4 x i1> %3,
    iXLen 0, iXLen %4, iXLen 1)

  ret <vscale x 4 x i8> %a
}

declare <vscale x 8 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv8i8.nxv8f32.iXLen(
  <vscale x 8 x i8>,
  <vscale x 8 x float>,
  float,
  iXLen, iXLen);

define <vscale x 8 x i8> @intrinsic_sf_vfnrclip_x_f_qf_nxv8i8_nxv8f32(<vscale x 8 x float> %0, float %1, iXLen %2) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_nxv8i8_nxv8f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    fsrmi a1, 0
; CHECK-NEXT:    vsetvli zero, a0, e8, m1, ta, ma
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v12, v8, fa0
; CHECK-NEXT:    fsrm a1
; CHECK-NEXT:    vmv.v.v v8, v12
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 8 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv8i8.nxv8f32.iXLen(
    <vscale x 8 x i8> undef,
    <vscale x 8 x float> %0,
    float %1,
    iXLen 0, iXLen %2)

  ret <vscale x 8 x i8> %a
}

declare <vscale x 8 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv8i8.nxv8f32.iXLen(
  <vscale x 8 x i8>,
  <vscale x 8 x float>,
  float,
  <vscale x 8 x i1>,
  iXLen, iXLen, iXLen);

define <vscale x 8 x i8> @intrinsic_sf_vfnrclip_x_f_qf_mask_nxv8i8_nxv8f32(<vscale x 8 x i8> %0, <vscale x 8 x float> %1, float %2, <vscale x 8 x i1> %3, iXLen %4) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_mask_nxv8i8_nxv8f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    fsrmi a1, 0
; CHECK-NEXT:    vsetvli zero, a0, e8, m1, ta, mu
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v8, v12, fa0, v0.t
; CHECK-NEXT:    fsrm a1
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 8 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv8i8.nxv8f32.iXLen(
    <vscale x 8 x i8> %0,
    <vscale x 8 x float> %1,
    float %2,
    <vscale x 8 x i1> %3,
    iXLen 0, iXLen %4, iXLen 1)

  ret <vscale x 8 x i8> %a
}

declare <vscale x 16 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv16i8.nxv16f32.iXLen(
  <vscale x 16 x i8>,
  <vscale x 16 x float>,
  float,
  iXLen, iXLen);

define <vscale x 16 x i8> @intrinsic_sf_vfnrclip_x_f_qf_nxv16i8_nxv16f32(<vscale x 16 x float> %0, float %1, iXLen %2) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_nxv16i8_nxv16f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    fsrmi a1, 0
; CHECK-NEXT:    vsetvli zero, a0, e8, m2, ta, ma
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v16, v8, fa0
; CHECK-NEXT:    fsrm a1
; CHECK-NEXT:    vmv.v.v v8, v16
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 16 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.nxv16i8.nxv16f32.iXLen(
    <vscale x 16 x i8> undef,
    <vscale x 16 x float> %0,
    float %1,
    iXLen 0, iXLen %2)

  ret <vscale x 16 x i8> %a
}

declare <vscale x 16 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv16i8.nxv16f32.iXLen(
  <vscale x 16 x i8>,
  <vscale x 16 x float>,
  float,
  <vscale x 16 x i1>,
  iXLen, iXLen, iXLen);

define <vscale x 16 x i8> @intrinsic_sf_vfnrclip_x_f_qf_mask_nxv16i8_nxv16f32(<vscale x 16 x i8> %0, <vscale x 16 x float> %1, float %2, <vscale x 16 x i1> %3, iXLen %4) nounwind {
; CHECK-LABEL: intrinsic_sf_vfnrclip_x_f_qf_mask_nxv16i8_nxv16f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    fsrmi a1, 0
; CHECK-NEXT:    vsetvli zero, a0, e8, m2, ta, mu
; CHECK-NEXT:    sf.vfnrclip.x.f.qf v8, v16, fa0, v0.t
; CHECK-NEXT:    fsrm a1
; CHECK-NEXT:    ret
entry:
  %a = call <vscale x 16 x i8> @llvm.riscv.sf.vfnrclip.x.f.qf.mask.nxv16i8.nxv16f32.iXLen(
    <vscale x 16 x i8> %0,
    <vscale x 16 x float> %1,
    float %2,
    <vscale x 16 x i1> %3,
    iXLen 0, iXLen %4, iXLen 1)

  ret <vscale x 16 x i8> %a
}
