(* Test 2 - Type Definitions
decl test L:0 O:0 TYPE-PROGRAM S:0
  symtab
    agerange SYMBOL-GLOBAL L:1 O:0 TYPE-SUBRANGE S:1
    five SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    four SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    myarray SYMBOL-GLOBAL L:1 O:0 TYPE-ARRAY S:16
    myenum SYMBOL-GLOBAL L:1 O:0 TYPE-ENUMERATION S:2
    mynumber SYMBOL-GLOBAL L:1 O:0 TYPE-INTEGER S:2
    myrecord SYMBOL-GLOBAL L:1 O:0 TYPE-RECORD S:6
    one SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    three SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    two SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
  decl mynumber L:1 O:0 TYPE-INTEGER S:2
  decl myarray L:1 O:0 TYPE-ARRAY S:16
  decl myrecord L:1 O:0 TYPE-RECORD S:6
    symtab
      i SYMBOL-GLOBAL L:0 O:0 TYPE-INTEGER S:2
      r SYMBOL-GLOBAL L:0 O:2 TYPE-REAL S:4
  decl myenum L:1 O:0 TYPE-ENUMERATION S:2
  decl agerange L:1 O:0 TYPE-SUBRANGE S:1
*)

Program Test;

Type
  MyNumber = Integer;
  MyArray = Array[1..5] Of Integer;
  MyRecord = Record
    i : Integer;
    r : Real;
  End;
  MyEnum = (One, Two, Three, Four, Five);
  AgeRange = 2..99;

Begin
End.
