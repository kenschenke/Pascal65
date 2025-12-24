(* Test 7 - Pointers
decl test L:0 O:0 TYPE-PROGRAM S:0
  symtab
    functype SYMBOL-GLOBAL L:1 O:0 TYPE-ROUTINE-POINTER S:4
    myrec SYMBOL-GLOBAL L:1 O:0 TYPE-RECORD S:8
    pi SYMBOL-GLOBAL L:1 O:0 TYPE-POINTER S:2
    pp SYMBOL-GLOBAL L:1 O:2 TYPE-DECLARED S:4
    pr SYMBOL-GLOBAL L:1 O:1 TYPE-POINTER S:8
    proctype SYMBOL-GLOBAL L:1 O:0 TYPE-ROUTINE-POINTER S:4
  decl proctype L:1 O:0 TYPE-ROUTINE-POINTER S:4
  decl functype L:1 O:0 TYPE-ROUTINE-POINTER S:4
  decl myrec L:1 O:0 TYPE-RECORD S:8
    symtab
      a SYMBOL-GLOBAL L:0 O:0 TYPE-INTEGER S:2
      b SYMBOL-GLOBAL L:0 O:2 TYPE-INTEGER S:2
      r SYMBOL-GLOBAL L:0 O:4 TYPE-REAL S:4
  decl pi L:1 O:0 TYPE-POINTER S:2
  decl pr L:1 O:1 TYPE-POINTER S:8
  decl pp L:1 O:2 TYPE-ROUTINE-POINTER S:4
*)

Program Test;

Type
  ProcType = Procedure(num : Integer);
  FuncType = Function(a : Boolean) : Char;
  MyRec = Record
    a, b : Integer;
    r : Real;
  End;

Var
  pi : ^Integer;
  pr : ^MyRec;
  pp : ProcType;

Begin
  pi := @i;
  pi^ := 12345;
  pr^.a := 123;
  pi := @arr[1];
  ptr^[5] := 234;
  pp := @MyProc;
  pp(456);
End.
