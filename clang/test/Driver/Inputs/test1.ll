; ModuleID = 'test1.cpp'
source_filename = "test1.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64"

; Function Attrs: mustprogress noinline
define spir_func noundef i32 @_Z9foo_func1ii(i32 noundef %a, i32 noundef %b) local_unnamed_addr #0 {
entry:
  %call = tail call spir_func noundef i32 @_Z9lib_func4i(i32 noundef %b)
  %call1 = tail call spir_func noundef i32 @_Z9bar_func1ii(i32 noundef %a, i32 noundef %call)
  ret i32 %call1
}

declare spir_func noundef i32 @_Z9bar_func1ii(i32 noundef, i32 noundef) local_unnamed_addr #1

declare spir_func noundef i32 @_Z9lib_func4i(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress
define spir_func noundef i32 @_Z9foo_func2iii(i32 noundef %c, i32 noundef %d, i32 noundef %e) local_unnamed_addr #2 {
entry:
  %call = tail call spir_func noundef i32 @_Z9foo_func1ii(i32 noundef %c, i32 noundef %d)
  %mul = mul nsw i32 %call, %e
  ret i32 %mul
}

attributes #0 = { mustprogress noinline "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { mustprogress "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
