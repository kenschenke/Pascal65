(* Test 4 - Arrays
decl test L:0 O:0 TYPE-PROGRAM S:0
  symtab
    arr1 SYMBOL-GLOBAL L:1 O:0 TYPE-ARRAY S:16
    arr2 SYMBOL-GLOBAL L:1 O:1 TYPE-ARRAY S:16
    arr3 SYMBOL-GLOBAL L:1 O:2 TYPE-DECLARED S:46
    arraytype SYMBOL-GLOBAL L:1 O:0 TYPE-ARRAY S:46
  decl arraytype L:1 O:0 TYPE-ARRAY S:46
  decl arr1 L:1 O:0 TYPE-ARRAY S:16
  decl arr2 L:1 O:1 TYPE-ARRAY S:16
  decl arr3 L:1 O:2 TYPE-ARRAY S:46
*)

Program Test;

Type ArrayType = Array[1..10] Of Real;

Var
  arr1 : Array[1..5] Of Integer;
  arr2 : Array[5] Of Integer;
  arr3 : ArrayType;

Begin
End.
