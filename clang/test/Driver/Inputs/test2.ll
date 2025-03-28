; ModuleID = 'test2.cpp'
source_filename = "test2.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none)
define spir_func noundef i32 @_Z9bar_func1ii(i32 noundef %a, i32 noundef %b) local_unnamed_addr #0 {
entry:
  %add = add nsw i32 %b, %a
  ret i32 %add
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define spir_func noundef i32 @_Z9bar_func2iii(i32 noundef %c, i32 noundef %d, i32 noundef %e) local_unnamed_addr #1 {
entry:
  %call = tail call spir_func noundef i32 @_Z9bar_func1ii(i32 noundef %c, i32 noundef %d)
  %add = add nsw i32 %call, %e
  ret i32 %add
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
