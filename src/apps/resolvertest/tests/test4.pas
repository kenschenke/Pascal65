(* Test 4 - Arrays
decl test 
  symtab
    arr1 SYMBOL-GLOBAL L:1 O:0 TYPE-ARRAY S:16
    arr2 SYMBOL-GLOBAL L:1 O:1 TYPE-ARRAY S:16
    arr3 SYMBOL-GLOBAL L:1 O:2 TYPE-ARRAY S:46
    arr4 SYMBOL-GLOBAL L:1 O:3 TYPE-ARRAY S:96
    arr5 SYMBOL-GLOBAL L:1 O:4 TYPE-ARRAY S:96
    arr6 SYMBOL-GLOBAL L:1 O:5 TYPE-ARRAY S:96
    arr7 SYMBOL-GLOBAL L:1 O:6 TYPE-ARRAY S:36
    arr8 SYMBOL-GLOBAL L:1 O:7 TYPE-ARRAY S:6
    arr9 SYMBOL-GLOBAL L:1 O:8 TYPE-ARRAY S:6
    arraytype SYMBOL-GLOBAL L:1 O:0 TYPE-ARRAY S:46
    dyntype SYMBOL-GLOBAL L:1 O:0 TYPE-ARRAY S:6
    recordtype SYMBOL-GLOBAL L:1 O:0 TYPE-RECORD S:6
  decl arraytype L:1 O:0 TYPE-ARRAY S:46
  decl recordtype L:1 O:0 TYPE-RECORD S:6
    symtab
      i SYMBOL-GLOBAL L:0 O:0 TYPE-INTEGER S:2
      j SYMBOL-GLOBAL L:0 O:2 TYPE-INTEGER S:2
      str SYMBOL-GLOBAL L:0 O:4 TYPE-STRING-VAR S:2
  decl dyntype L:1 O:0 TYPE-ARRAY S:6
  decl arr1 L:1 O:0 TYPE-ARRAY S:16
  decl arr2 L:1 O:1 TYPE-ARRAY S:16
  decl arr3 L:1 O:2 TYPE-ARRAY S:46
  decl arr4 L:1 O:3 TYPE-ARRAY S:96
  decl arr5 L:1 O:4 TYPE-ARRAY S:96
  decl arr6 L:1 O:5 TYPE-ARRAY S:96
  decl arr7 L:1 O:6 TYPE-ARRAY S:36
  decl arr8 L:1 O:7 TYPE-ARRAY S:6
  decl arr9 L:1 O:8 TYPE-ARRAY S:6
*)

Program Test;

Type
  ArrayType = Array[1..10] Of Real;
  RecordType = Record
    i, j : Integer;
    str : String;
  End;
  DynType = Array Of Integer;

Var
  arr1 : Array[1..5] Of Integer;
  arr2 : Array[5] Of Integer;
  arr3 : ArrayType;
  arr4 : Array[1..5] Of Array[1..6] Of Integer;
  arr5 : Array[1..5,1..6] Of Integer;
  arr6 : Array[5,6] Of Integer;
  arr7 : Array[1..5] Of RecordType;
  arr8 : Array Of Integer;
  arr9 : DynType;

Begin
  arr7[1].i := 1234;
End.
