; RUN: opt < %s -aa-pipeline=tbaa,basic-aa -passes=function-attrs -S | FileCheck %s

; FunctionAttrs should make use of TBAA.

; Add the readnone attribute, since the only access is a store which TBAA
; says is to constant memory.
;
; It's unusual to see a store to constant memory, but it isn't necessarily
; invalid, as it's possible that this only happens after optimization on a
; code path which isn't ever executed.

; CHECK: define void @test0_yes(ptr captures(none) %p) #0 {
define void @test0_yes(ptr %p) nounwind willreturn {
  store i32 0, ptr %p, !tbaa !1
  ret void
}

; CHECK: define void @test0_no(ptr writeonly captures(none) initializes((0, 4)) %p) #1 {
define void @test0_no(ptr %p) nounwind willreturn {
  store i32 0, ptr %p, !tbaa !2
  ret void
}

; Add the readnone attribute, since there's just a call to a function which
; TBAA says only accesses constant memory.

; CHECK: define void @test1_yes(ptr captures(none) %p) #2 {
define void @test1_yes(ptr %p) nounwind willreturn {
  call void @callee(ptr %p), !tbaa !1
  ret void
}

; CHECK: define void @test1_no(ptr %p) #3 {
define void @test1_no(ptr %p) nounwind willreturn {
  call void @callee(ptr %p), !tbaa !2
  ret void
}

; Add the readonly attribute, as above, but this time BasicAA will say
; that the function accesses memory through its arguments, which TBAA
; still says that the function doesn't write to memory.
;
; This is unusual, since the function is memcpy, but as above, this
; isn't necessarily invalid.

; CHECK: define void @test2_yes(ptr captures(none) %p, ptr captures(none) %q, i64 %n) #0 {
define void @test2_yes(ptr %p, ptr %q, i64 %n) nounwind willreturn {
  call void @llvm.memcpy.p0.p0.i64(ptr %p, ptr %q, i64 %n, i1 false), !tbaa !1
  ret void
}

; CHECK: define void @test2_no(ptr writeonly captures(none) %p, ptr readonly captures(none) %q, i64 %n) #4 {
define void @test2_no(ptr %p, ptr %q, i64 %n) nounwind willreturn {
  call void @llvm.memcpy.p0.p0.i64(ptr %p, ptr %q, i64 %n, i1 false), !tbaa !2
  ret void
}

; Similar to the others, va_arg only accesses memory through its operand.

; CHECK: define i32 @test3_yes(ptr captures(none) %p) #0 {
define i32 @test3_yes(ptr %p) nounwind willreturn {
  %t = va_arg ptr %p, i32, !tbaa !1
  ret i32 %t
}

; CHECK: define i32 @test3_no(ptr captures(none) %p) #4 {
define i32 @test3_no(ptr %p) nounwind willreturn {
  %t = va_arg ptr %p, i32, !tbaa !2
  ret i32 %t
}

declare void @callee(ptr %p) nounwind willreturn
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1) nounwind willreturn

; CHECK: attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
; CHECK: attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) }
; CHECK: attributes #2 = { mustprogress nofree nosync nounwind willreturn memory(none) }
; CHECK: attributes #3 = { mustprogress nounwind willreturn }
; CHECK: attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) }
; CHECK: attributes #5 = { nounwind willreturn }
; CHECK: attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }

; Root note.
!0 = !{ }

; Invariant memory.
!1 = !{!3, !3, i64 0, i1 1 }
; Not invariant memory.
!2 = !{!3, !3, i64 0, i1 0 }
!3 = !{ !"foo", !0 }
