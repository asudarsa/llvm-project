// RUN: mlir-opt -convert-parallel-loops-to-gpu -split-input-file -verify-diagnostics %s | FileCheck %s -dump-input-on-failure

// 2-d parallel loop mapped to block.y and block.x

func @parallel_loop_bidy_bidx(%arg0 : index, %arg1 : index, %arg2 : index,
                              %arg3 : index, %arg4 : index, 
                              %buf : memref<?x?xf32>,
                              %res : memref<?x?xf32>) {
  %step = constant 2 : index
  loop.parallel (%i0, %i1) = (%arg0, %arg1) to (%arg2, %arg3)
                                          step (%arg4, %step)  {
    %val = load %buf[%i0, %i1] : memref<?x?xf32>
    store %val, %res[%i1, %i0] : memref<?x?xf32>
  } { mapping = [{processor = 1, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}, {processor = 0, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}] }
  return
}

// CHECK:       #[[MAP0:.*]] = affine_map<()[s0, s1, s2] -> ((s0 - s1) ceildiv s2)>
// CHECK:       #[[MAP1:.*]] = affine_map<(d0)[s0, s1] -> (d0 * s0 + s1)>

// CHECK:       module {
// CHECK-LABEL:   func @parallel_loop_bidy_bidx(
// CHECK-SAME:                                  [[VAL_0:%.*]]: index, [[VAL_1:%.*]]: index, [[VAL_2:%.*]]: index, [[VAL_3:%.*]]: index, [[VAL_4:%.*]]: index, [[VAL_5:%.*]]: memref<?x?xf32>, [[VAL_6:%.*]]: memref<?x?xf32>) {
// CHECK:           [[VAL_7:%.*]] = constant 2 : index
// CHECK:           [[VAL_8:%.*]] = constant 1 : index
// CHECK:           [[VAL_9:%.*]] = affine.apply #[[MAP0]](){{\[}}[[VAL_2]], [[VAL_0]], [[VAL_4]]]
// CHECK:           [[VAL_10:%.*]] = affine.apply #[[MAP0]](){{\[}}[[VAL_3]], [[VAL_1]], [[VAL_7]]]
// CHECK:           gpu.launch blocks([[VAL_11:%.*]], [[VAL_12:%.*]], [[VAL_13:%.*]]) in ([[VAL_14:%.*]] = [[VAL_10]], [[VAL_15:%.*]] = [[VAL_9]], [[VAL_16:%.*]] = [[VAL_8]]) threads([[VAL_17:%.*]], [[VAL_18:%.*]], [[VAL_19:%.*]]) in ([[VAL_20:%.*]] = [[VAL_8]], [[VAL_21:%.*]] = [[VAL_8]], [[VAL_22:%.*]] = [[VAL_8]]) {
// CHECK:             [[VAL_23:%.*]] = affine.apply #[[MAP1]]([[VAL_12]]){{\[}}[[VAL_4]], [[VAL_0]]]
// CHECK:             [[VAL_24:%.*]] = affine.apply #[[MAP1]]([[VAL_11]]){{\[}}[[VAL_7]], [[VAL_1]]]
// CHECK:             [[VAL_25:%.*]] = load [[VAL_5]]{{\[}}[[VAL_23]], [[VAL_24]]] : memref<?x?xf32>
// CHECK:             store [[VAL_25]], [[VAL_6]]{{\[}}[[VAL_24]], [[VAL_23]]] : memref<?x?xf32>
// CHECK:             gpu.terminator
// CHECK:           }
// CHECK:           return
// CHECK:         }
// CHECK:       }

// -----

// tiled 2-d parallel loop mapped to block.y and block.x and thread.y and thread.x.

func @parallel_loop_tiled(%arg0 : index, %arg1 : index, %arg2 : index,
                        %arg3 : index,
                        %buf : memref<?x?xf32>,
                        %res : memref<?x?xf32>) {
  %zero = constant 0 : index
  %one = constant 1 : index
  %four = constant 4 : index
  loop.parallel (%i0, %i1) = (%arg0, %arg1) to (%arg2, %arg3)
                                          step (%four, %four)  {
    loop.parallel (%si0, %si1) = (%zero, %zero) to (%four, %four)
                                            step (%one, %one)  {
      %idx0 = addi %i0, %si0 : index
      %idx1 = addi %i1, %si1 : index
      %val = load %buf[%idx0, %idx1] : memref<?x?xf32>
      store %val, %res[%idx1, %idx0] : memref<?x?xf32>
    } { mapping = [
        {processor = 4, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>},
        {processor = 3, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}
     ] }
  } { mapping = [
      {processor = 1, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>},
      {processor = 0, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}
    ] }
  return
}

// CHECK:       #[[MAP0:.*]] = affine_map<()[s0, s1, s2] -> ((s0 - s1) ceildiv s2)>
// CHECK:       #[[MAP1:.*]] = affine_map<(d0)[s0, s1] -> (d0 * s0 + s1)>

// CHECK:       module {
// CHECK-LABEL:   func @parallel_loop_tiled(
// CHECK-SAME:                              [[VAL_26:%.*]]: index, [[VAL_27:%.*]]: index, [[VAL_28:%.*]]: index, [[VAL_29:%.*]]: index, [[VAL_30:%.*]]: memref<?x?xf32>, [[VAL_31:%.*]]: memref<?x?xf32>) {
// CHECK:           [[VAL_32:%.*]] = constant 0 : index
// CHECK:           [[VAL_33:%.*]] = constant 1 : index
// CHECK:           [[VAL_34:%.*]] = constant 4 : index
// CHECK:           [[VAL_35:%.*]] = constant 1 : index
// CHECK:           [[VAL_36:%.*]] = affine.apply #[[MAP0]](){{\[}}[[VAL_28]], [[VAL_26]], [[VAL_34]]]
// CHECK:           [[VAL_37:%.*]] = affine.apply #[[MAP0]](){{\[}}[[VAL_29]], [[VAL_27]], [[VAL_34]]]
// CHECK:           [[VAL_38:%.*]] = affine.apply #[[MAP0]](){{\[}}[[VAL_34]], [[VAL_32]], [[VAL_33]]]
// CHECK:           [[VAL_39:%.*]] = affine.apply #[[MAP0]](){{\[}}[[VAL_34]], [[VAL_32]], [[VAL_33]]]
// CHECK:           gpu.launch blocks([[VAL_40:%.*]], [[VAL_41:%.*]], [[VAL_42:%.*]]) in ([[VAL_43:%.*]] = [[VAL_37]], [[VAL_44:%.*]] = [[VAL_36]], [[VAL_45:%.*]] = [[VAL_35]]) threads([[VAL_46:%.*]], [[VAL_47:%.*]], [[VAL_48:%.*]]) in ([[VAL_49:%.*]] = [[VAL_39]], [[VAL_50:%.*]] = [[VAL_38]], [[VAL_51:%.*]] = [[VAL_35]]) {
// CHECK:             [[VAL_52:%.*]] = affine.apply #[[MAP1]]([[VAL_41]]){{\[}}[[VAL_34]], [[VAL_26]]]
// CHECK:             [[VAL_53:%.*]] = affine.apply #[[MAP1]]([[VAL_40]]){{\[}}[[VAL_34]], [[VAL_27]]]
// CHECK:             [[VAL_54:%.*]] = affine.apply #[[MAP1]]([[VAL_47]]){{\[}}[[VAL_33]], [[VAL_32]]]
// CHECK:             [[VAL_55:%.*]] = affine.apply #[[MAP1]]([[VAL_46]]){{\[}}[[VAL_33]], [[VAL_32]]]
// CHECK:             [[VAL_56:%.*]] = addi [[VAL_52]], [[VAL_54]] : index
// CHECK:             [[VAL_57:%.*]] = addi [[VAL_53]], [[VAL_55]] : index
// CHECK:             [[VAL_58:%.*]] = load [[VAL_30]]{{\[}}[[VAL_56]], [[VAL_57]]] : memref<?x?xf32>
// CHECK:             store [[VAL_58]], [[VAL_31]]{{\[}}[[VAL_57]], [[VAL_56]]] : memref<?x?xf32>
// CHECK:             gpu.terminator
// CHECK:           }
// CHECK:           return
// CHECK:         }
// CHECK:       }

// -----

// 2-d parallel loop mapped to block.y and sequential

func @parallel_loop_bidy_seq(%arg0 : index, %arg1 : index, %arg2 : index,
                             %arg3 : index, %arg4 : index,
                             %buf : memref<?x?xf32>,
                             %res : memref<?x?xf32>) {
  %step = constant 2 : index
  loop.parallel (%i0, %i1) = (%arg0, %arg1) to (%arg2, %arg3)
                                          step (%arg4, %step)  {
    %val = load %buf[%i0, %i1] : memref<?x?xf32>
    store %val, %res[%i1, %i0] : memref<?x?xf32>
  } { mapping = [
      {processor = 1, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>},
      {processor = 6, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}
    ] }
  return
}

// CHECK:       #[[MAP0:.*]] = affine_map<()[s0, s1, s2] -> ((s0 - s1) ceildiv s2)>
// CHECK:       #[[MAP1:.*]] = affine_map<(d0)[s0, s1] -> (d0 * s0 + s1)>

// CHECK:       module {
// CHECK-LABEL:   func @parallel_loop_bidy_seq(
// CHECK-SAME:                                 [[VAL_59:%.*]]: index, [[VAL_60:%.*]]: index, [[VAL_61:%.*]]: index, [[VAL_62:%.*]]: index, [[VAL_63:%.*]]: index, [[VAL_64:%.*]]: memref<?x?xf32>, [[VAL_65:%.*]]: memref<?x?xf32>) {
// CHECK:           [[VAL_66:%.*]] = constant 2 : index
// CHECK:           [[VAL_67:%.*]] = constant 1 : index
// CHECK:           [[VAL_68:%.*]] = affine.apply #[[MAP0]](){{\[}}[[VAL_61]], [[VAL_59]], [[VAL_63]]]
// CHECK:           gpu.launch blocks([[VAL_69:%.*]], [[VAL_70:%.*]], [[VAL_71:%.*]]) in ([[VAL_72:%.*]] = [[VAL_67]], [[VAL_73:%.*]] = [[VAL_68]], [[VAL_74:%.*]] = [[VAL_67]]) threads([[VAL_75:%.*]], [[VAL_76:%.*]], [[VAL_77:%.*]]) in ([[VAL_78:%.*]] = [[VAL_67]], [[VAL_79:%.*]] = [[VAL_67]], [[VAL_80:%.*]] = [[VAL_67]]) {
// CHECK:             [[VAL_81:%.*]] = affine.apply #[[MAP1]]([[VAL_70]]){{\[}}[[VAL_63]], [[VAL_59]]]
// CHECK:             loop.for [[VAL_82:%.*]] = [[VAL_60]] to [[VAL_62]] step [[VAL_66]] {
// CHECK:               [[VAL_83:%.*]] = load [[VAL_64]]{{\[}}[[VAL_81]], [[VAL_82]]] : memref<?x?xf32>
// CHECK:               store [[VAL_83]], [[VAL_65]]{{\[}}[[VAL_82]], [[VAL_81]]] : memref<?x?xf32>
// CHECK:             }
// CHECK:             gpu.terminator
// CHECK:           }
// CHECK:           return
// CHECK:         }
// CHECK:       }

// -----

// tiled 2-d parallel loop mapped to block.y and seq. and thread.y and seq.

func @parallel_loop_tiled_seq(%arg0 : index, %arg1 : index, %arg2 : index,
                              %arg3 : index,
                              %buf : memref<?x?xf32>,
                              %res : memref<?x?xf32>) {
  %zero = constant 0 : index
  %one = constant 1 : index
  %four = constant 4 : index
  loop.parallel (%i0, %i1) = (%arg0, %arg1) to (%arg2, %arg3)
                                          step (%four, %four)  {
    loop.parallel (%si0, %si1) = (%zero, %zero) to (%four, %four)
                                            step (%one, %one)  {
      %idx0 = addi %i0, %si0 : index
      %idx1 = addi %i1, %si1 : index
      %val = load %buf[%idx0, %idx1] : memref<?x?xf32>
      store %val, %res[%idx1, %idx0] : memref<?x?xf32>
    } { mapping = [
        {processor = 4, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>},
        {processor = 6, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}
      ] }
  } { mapping = [
      {processor = 1, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>},
      {processor = 6, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}
    ] }
  return
}

// CHECK:       #[[MAP0:.*]] = affine_map<()[s0, s1, s2] -> ((s0 - s1) ceildiv s2)>
// CHECK:       #[[MAP1:.*]] = affine_map<(d0)[s0, s1] -> (d0 * s0 + s1)>

// CHECK:       module {
// CHECK-LABEL:   func @parallel_loop_tiled_seq(
// CHECK-SAME:                                  [[VAL_84:%.*]]: index, [[VAL_85:%.*]]: index, [[VAL_86:%.*]]: index, [[VAL_87:%.*]]: index, [[VAL_88:%.*]]: memref<?x?xf32>, [[VAL_89:%.*]]: memref<?x?xf32>) {
// CHECK:           [[VAL_90:%.*]] = constant 0 : index
// CHECK:           [[VAL_91:%.*]] = constant 1 : index
// CHECK:           [[VAL_92:%.*]] = constant 4 : index
// CHECK:           [[VAL_93:%.*]] = constant 1 : index
// CHECK:           [[VAL_94:%.*]] = affine.apply #[[MAP0]](){{\[}}[[VAL_86]], [[VAL_84]], [[VAL_92]]]
// CHECK:           [[VAL_95:%.*]] = affine.apply #[[MAP0]](){{\[}}[[VAL_92]], [[VAL_90]], [[VAL_91]]]
// CHECK:           gpu.launch blocks([[VAL_96:%.*]], [[VAL_97:%.*]], [[VAL_98:%.*]]) in ([[VAL_99:%.*]] = [[VAL_93]], [[VAL_100:%.*]] = [[VAL_94]], [[VAL_101:%.*]] = [[VAL_93]]) threads([[VAL_102:%.*]], [[VAL_103:%.*]], [[VAL_104:%.*]]) in ([[VAL_105:%.*]] = [[VAL_93]], [[VAL_106:%.*]] = [[VAL_95]], [[VAL_107:%.*]] = [[VAL_93]]) {
// CHECK:             [[VAL_108:%.*]] = affine.apply #[[MAP1]]([[VAL_97]]){{\[}}[[VAL_92]], [[VAL_84]]]
// CHECK:             loop.for [[VAL_109:%.*]] = [[VAL_85]] to [[VAL_87]] step [[VAL_92]] {
// CHECK:               [[VAL_110:%.*]] = affine.apply #[[MAP1]]([[VAL_103]]){{\[}}[[VAL_91]], [[VAL_90]]]
// CHECK:               loop.for [[VAL_111:%.*]] = [[VAL_90]] to [[VAL_92]] step [[VAL_91]] {
// CHECK:                 [[VAL_112:%.*]] = addi [[VAL_108]], [[VAL_110]] : index
// CHECK:                 [[VAL_113:%.*]] = addi [[VAL_109]], [[VAL_111]] : index
// CHECK:                 [[VAL_114:%.*]] = load [[VAL_88]]{{\[}}[[VAL_112]], [[VAL_113]]] : memref<?x?xf32>
// CHECK:                 store [[VAL_114]], [[VAL_89]]{{\[}}[[VAL_113]], [[VAL_112]]] : memref<?x?xf32>
// CHECK:               }
// CHECK:             }
// CHECK:             gpu.terminator
// CHECK:           }
// CHECK:           return
// CHECK:         }
// CHECK:       }

// -----

#map0 = affine_map<(d0, d1)[s0, s1] -> (d0 * s1 + s0 + d1)>
#map1 = affine_map<(d0)[s0] -> (2, -d0 + s0)>
#map2 = affine_map<(d0)[s0] -> (3, -d0 + s0)>
#map3 = affine_map<(d0, d1)[s0, s1, s2] -> (d0 * s1 + s0 + d1 * s2)>

module {
  func @sum(%arg0: memref<?x?xf32, #map0>, %arg1: memref<?x?xf32, #map0>, %arg2: memref<?x?xf32, #map0>) {
    %c1 = constant 1 : index
    %c0 = constant 0 : index
    %c3 = constant 3 : index
    %c2 = constant 2 : index
    %0 = dim %arg0, 0 : memref<?x?xf32, #map0>
    %1 = dim %arg0, 1 : memref<?x?xf32, #map0>
    loop.parallel (%arg3, %arg4) = (%c0, %c0) to (%0, %1) step (%c2, %c3) {
      %2 = dim %arg0, 0 : memref<?x?xf32, #map0>
      %3 = affine.min #map1(%arg3)[%2]
      %4 = dim %arg0, 1 : memref<?x?xf32, #map0>
      %5 = affine.min #map2(%arg4)[%4]
      %6 = std.subview %arg0[%arg3, %arg4][%3, %5][%c1, %c1] : memref<?x?xf32, #map0> to memref<?x?xf32, #map3>
      %7 = dim %arg1, 0 : memref<?x?xf32, #map0>
      %8 = affine.min #map1(%arg3)[%7]
      %9 = dim %arg1, 1 : memref<?x?xf32, #map0>
      %10 = affine.min #map2(%arg4)[%9]
      %11 = std.subview %arg1[%arg3, %arg4][%8, %10][%c1, %c1] : memref<?x?xf32, #map0> to memref<?x?xf32, #map3>
      %12 = dim %arg2, 0 : memref<?x?xf32, #map0>
      %13 = affine.min #map1(%arg3)[%12]
      %14 = dim %arg2, 1 : memref<?x?xf32, #map0>
      %15 = affine.min #map2(%arg4)[%14]
      %16 = std.subview %arg2[%arg3, %arg4][%13, %15][%c1, %c1] : memref<?x?xf32, #map0> to memref<?x?xf32, #map3>
      loop.parallel (%arg5, %arg6) = (%c0, %c0) to (%3, %5) step (%c1, %c1) {
        %17 = load %6[%arg5, %arg6] : memref<?x?xf32, #map3>
        %18 = load %11[%arg5, %arg6] : memref<?x?xf32, #map3>
        %19 = load %16[%arg5, %arg6] : memref<?x?xf32, #map3>
        %20 = addf %17, %18 : f32
        store %20, %16[%arg5, %arg6] : memref<?x?xf32, #map3>
        loop.yield
      } {mapping = [{bound = affine_map<(d0) -> (d0)>, map = affine_map<(d0) -> (d0)>, processor = 3 : i64}, {bound = affine_map<(d0) -> (d0)>, map = affine_map<(d0) -> (d0)>, processor = 4 : i64}]}
      loop.yield
    } {mapping = [{bound = affine_map<(d0) -> (d0)>, map = affine_map<(d0) -> (d0)>, processor = 0 : i64}, {bound = affine_map<(d0) -> (d0)>, map = affine_map<(d0) -> (d0)>, processor = 1 : i64}]}
    return
  }
}

// CHECK:       #[[MAP0:.*]] = affine_map<(d0, d1)[s0, s1] -> (d0 * s1 + s0 + d1)>
// CHECK:       #[[MAP1:.*]] = affine_map<()[s0, s1, s2] -> ((s0 - s1) ceildiv s2)>
// CHECK:       #[[MAP2:.*]] = affine_map<(d0)[s0, s1] -> (d0 * s0 + s1)>
// CHECK:       #[[MAP3:.*]] = affine_map<(d0)[s0] -> (2, -d0 + s0)>
// CHECK:       #[[MAP4:.*]] = affine_map<(d0)[s0] -> (3, -d0 + s0)>
// CHECK:       #[[MAP5:.*]] = affine_map<(d0, d1)[s0, s1, s2] -> (d0 * s1 + s0 + d1 * s2)>

// CHECK:       module {
// CHECK-LABEL:   func @sum(
// CHECK-SAME:              [[VAL_0:%.*]]: memref<?x?xf32, #[[MAP0]]>, [[VAL_1:%.*]]: memref<?x?xf32, #[[MAP0]]>, [[VAL_2:%.*]]: memref<?x?xf32, #[[MAP0]]>) {
// CHECK:           [[VAL_3:%.*]] = constant 1 : index
// CHECK:           [[VAL_4:%.*]] = constant 0 : index
// CHECK:           [[VAL_5:%.*]] = constant 3 : index
// CHECK:           [[VAL_6:%.*]] = constant 2 : index
// CHECK:           [[VAL_7:%.*]] = dim [[VAL_0]], 0 : memref<?x?xf32, #[[MAP0]]>
// CHECK:           [[VAL_8:%.*]] = dim [[VAL_0]], 1 : memref<?x?xf32, #[[MAP0]]>
// CHECK:           [[VAL_9:%.*]] = constant 1 : index
// CHECK:           [[VAL_10:%.*]] = affine.apply #[[MAP1]](){{\[}}[[VAL_7]], [[VAL_4]], [[VAL_6]]]
// CHECK:           [[VAL_11:%.*]] = affine.apply #[[MAP1]](){{\[}}[[VAL_8]], [[VAL_4]], [[VAL_5]]]
// CHECK:           [[VAL_12:%.*]] = constant 2 : index
// CHECK:           [[VAL_13:%.*]] = affine.apply #[[MAP1]](){{\[}}[[VAL_12]], [[VAL_4]], [[VAL_3]]]
// CHECK:           [[VAL_14:%.*]] = constant 3 : index
// CHECK:           [[VAL_15:%.*]] = affine.apply #[[MAP1]](){{\[}}[[VAL_14]], [[VAL_4]], [[VAL_3]]]
// CHECK:           gpu.launch blocks([[VAL_16:%.*]], [[VAL_17:%.*]], [[VAL_18:%.*]]) in ([[VAL_19:%.*]] = [[VAL_10]], [[VAL_20:%.*]] = [[VAL_11]], [[VAL_21:%.*]] = [[VAL_9]]) threads([[VAL_22:%.*]], [[VAL_23:%.*]], [[VAL_24:%.*]]) in ([[VAL_25:%.*]] = [[VAL_13]], [[VAL_26:%.*]] = [[VAL_15]], [[VAL_27:%.*]] = [[VAL_9]]) {
// CHECK:             [[VAL_28:%.*]] = affine.apply #[[MAP2]]([[VAL_16]]){{\[}}[[VAL_6]], [[VAL_4]]]
// CHECK:             [[VAL_29:%.*]] = affine.apply #[[MAP2]]([[VAL_17]]){{\[}}[[VAL_5]], [[VAL_4]]]
// CHECK:             [[VAL_30:%.*]] = dim [[VAL_0]], 0 : memref<?x?xf32, #[[MAP0]]>
// CHECK:             [[VAL_31:%.*]] = affine.min #[[MAP3]]([[VAL_28]]){{\[}}[[VAL_30]]]
// CHECK:             [[VAL_32:%.*]] = dim [[VAL_0]], 1 : memref<?x?xf32, #[[MAP0]]>
// CHECK:             [[VAL_33:%.*]] = affine.min #[[MAP4]]([[VAL_29]]){{\[}}[[VAL_32]]]
// CHECK:             [[VAL_34:%.*]] = subview [[VAL_0]]{{\[}}[[VAL_28]], [[VAL_29]]] {{\[}}[[VAL_31]], [[VAL_33]]] {{\[}}[[VAL_3]], [[VAL_3]]] : memref<?x?xf32, #[[MAP0]]> to memref<?x?xf32, #[[MAP5]]>
// CHECK:             [[VAL_35:%.*]] = dim [[VAL_1]], 0 : memref<?x?xf32, #[[MAP0]]>
// CHECK:             [[VAL_36:%.*]] = affine.min #[[MAP3]]([[VAL_28]]){{\[}}[[VAL_35]]]
// CHECK:             [[VAL_37:%.*]] = dim [[VAL_1]], 1 : memref<?x?xf32, #[[MAP0]]>
// CHECK:             [[VAL_38:%.*]] = affine.min #[[MAP4]]([[VAL_29]]){{\[}}[[VAL_37]]]
// CHECK:             [[VAL_39:%.*]] = subview [[VAL_1]]{{\[}}[[VAL_28]], [[VAL_29]]] {{\[}}[[VAL_36]], [[VAL_38]]] {{\[}}[[VAL_3]], [[VAL_3]]] : memref<?x?xf32, #[[MAP0]]> to memref<?x?xf32, #[[MAP5]]>
// CHECK:             [[VAL_40:%.*]] = dim [[VAL_2]], 0 : memref<?x?xf32, #[[MAP0]]>
// CHECK:             [[VAL_41:%.*]] = affine.min #[[MAP3]]([[VAL_28]]){{\[}}[[VAL_40]]]
// CHECK:             [[VAL_42:%.*]] = dim [[VAL_2]], 1 : memref<?x?xf32, #[[MAP0]]>
// CHECK:             [[VAL_43:%.*]] = affine.min #[[MAP4]]([[VAL_29]]){{\[}}[[VAL_42]]]
// CHECK:             [[VAL_44:%.*]] = subview [[VAL_2]]{{\[}}[[VAL_28]], [[VAL_29]]] {{\[}}[[VAL_41]], [[VAL_43]]] {{\[}}[[VAL_3]], [[VAL_3]]] : memref<?x?xf32, #[[MAP0]]> to memref<?x?xf32, #[[MAP5]]>
// CHECK:             [[VAL_45:%.*]] = affine.apply #[[MAP2]]([[VAL_22]]){{\[}}[[VAL_3]], [[VAL_4]]]
// CHECK:             [[VAL_46:%.*]] = cmpi "slt", [[VAL_45]], [[VAL_31]] : index
// CHECK:             loop.if [[VAL_46]] {
// CHECK:               [[VAL_47:%.*]] = affine.apply #[[MAP2]]([[VAL_23]]){{\[}}[[VAL_3]], [[VAL_4]]]
// CHECK:               [[VAL_48:%.*]] = cmpi "slt", [[VAL_47]], [[VAL_33]] : index
// CHECK:               loop.if [[VAL_48]] {
// CHECK:                 [[VAL_49:%.*]] = load [[VAL_34]]{{\[}}[[VAL_45]], [[VAL_47]]] : memref<?x?xf32, #[[MAP5]]>
// CHECK:                 [[VAL_50:%.*]] = load [[VAL_39]]{{\[}}[[VAL_45]], [[VAL_47]]] : memref<?x?xf32, #[[MAP5]]>
// CHECK:                 [[VAL_51:%.*]] = load [[VAL_44]]{{\[}}[[VAL_45]], [[VAL_47]]] : memref<?x?xf32, #[[MAP5]]>
// CHECK:                 [[VAL_52:%.*]] = addf [[VAL_49]], [[VAL_50]] : f32
// CHECK:                 store [[VAL_52]], [[VAL_44]]{{\[}}[[VAL_45]], [[VAL_47]]] : memref<?x?xf32, #[[MAP5]]>
// CHECK:               }
// CHECK:             }
// CHECK:             gpu.terminator
// CHECK:           }
// CHECK:           return
// CHECK:         }
// CHECK:       }

// -----

// Mapping to the same processor twice.

func @parallel_double_map(%arg0 : index, %arg1 : index, %arg2 : index,
                          %arg3 : index,
                          %buf : memref<?x?xf32>,
                          %res : memref<?x?xf32>) {
  %four = constant 4 : index
  // expected-error@+2 {{cannot redefine the bound for processor 1}}
  // expected-error@+1 {{failed to legalize operation 'loop.parallel'}}
  loop.parallel (%i0, %i1) = (%arg0, %arg1) to (%arg2, %arg3)
                                          step (%four, %four)  {
  } { mapping = [
      {processor = 1, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>},
      {processor = 1, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}
    ] }
  return
}

// -----

// Loop with loop-variant upper bound.

func @parallel_loop_loop_variant_bound(%arg0 : index, %arg1 : index, %arg2 : index,
                                       %arg3 : index,
                                       %buf : memref<?x?xf32>,
                                       %res : memref<?x?xf32>) {
  %zero = constant 0 : index
  %one = constant 1 : index
  %four = constant 4 : index
  // expected-error@+1 {{failed to legalize operation 'loop.parallel'}}
  loop.parallel (%i0, %i1) = (%arg0, %arg1) to (%arg2, %arg3)
                                          step (%four, %four)  {
    // expected-error@+1 {{cannot derive loop-invariant upper bound}}                                        
    loop.parallel (%si0, %si1) = (%zero, %zero) to (%i0, %i1)
                                            step (%one, %one)  {
      %idx0 = addi %i0, %si0 : index
      %idx1 = addi %i1, %si1 : index
      %val = load %buf[%idx0, %idx1] : memref<?x?xf32>
      store %val, %res[%idx1, %idx0] : memref<?x?xf32>
    } { mapping = [
        {processor = 4, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>},
        {processor = 6, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}
      ] }
  } { mapping = [
      {processor = 1, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>},
      {processor = 6, map = affine_map<(d0) -> (d0)>, bound = affine_map<(d0) -> (d0)>}
    ] }
  return
}
