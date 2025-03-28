; ModuleID = 'libsycl.cpp'
source_filename = "libsycl.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none)
define spir_func noundef range(i32 -2147483643, -2147483648) i32 @_Z9lib_func1i(i32 noundef %a) local_unnamed_addr #0 {
entry:
  %add = add nsw i32 %a, 5
  ret i32 %add
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none)
define spir_func noundef i32 @_Z9lib_func2i(i32 noundef %a) local_unnamed_addr #0 {
entry:
  %mul = mul nsw i32 %a, 5
  ret i32 %mul
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none)
define spir_func noundef range(i32 -2147483648, 2147483643) i32 @_Z9lib_func3i(i32 noundef %a) local_unnamed_addr #0 {
entry:
  %sub = add nsw i32 %a, -5
  ret i32 %sub
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none)
define spir_func noundef i32 @_Z9lib_func4i(i32 noundef %a) local_unnamed_addr #0 {
entry:
  %call = tail call spir_func noundef i32 @_Z9lib_func1i(i32 noundef %a)
  %call1 = tail call spir_func noundef i32 @_Z9lib_func2i(i32 noundef %a)
  %mul = mul nsw i32 %call1, %call
  ret i32 %mul
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
