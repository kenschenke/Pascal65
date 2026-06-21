(* Test 5 - Records
decl test 
  symtab
    myrec SYMBOL-GLOBAL L:1 O:0 TYPE-RECORD S:12
    otherrec SYMBOL-GLOBAL L:1 O:1 TYPE-RECORD S:20
    rec SYMBOL-GLOBAL L:1 O:0 TYPE-RECORD S:12
  decl myrec L:1 O:0 TYPE-RECORD S:12
    symtab
      i SYMBOL-GLOBAL L:0 O:0 TYPE-INTEGER S:2
      j SYMBOL-GLOBAL L:0 O:2 TYPE-INTEGER S:2
      r SYMBOL-GLOBAL L:0 O:4 TYPE-REAL S:4
      subrec SYMBOL-GLOBAL L:0 O:8 TYPE-RECORD S:4
  decl rec L:1 O:0 TYPE-RECORD S:12
    symtab
      i SYMBOL-GLOBAL L:0 O:0 TYPE-INTEGER S:2
      j SYMBOL-GLOBAL L:0 O:2 TYPE-INTEGER S:2
      r SYMBOL-GLOBAL L:0 O:4 TYPE-REAL S:4
      subrec SYMBOL-GLOBAL L:0 O:8 TYPE-RECORD S:4
  decl otherrec L:1 O:1 TYPE-RECORD S:20
    symtab
      a SYMBOL-GLOBAL L:0 O:0 TYPE-INTEGER S:2
      alsorec SYMBOL-GLOBAL L:0 O:16 TYPE-RECORD S:4
      rec SYMBOL-GLOBAL L:0 O:4 TYPE-RECORD S:12
      s SYMBOL-GLOBAL L:0 O:2 TYPE-STRING-VAR S:2
*)

Program Test;

Type
  MyRec = Record
    i, j : Integer;
    r : Real;
    SubRec : Record
      x, y : Integer;
    End;
  End;

Var
  rec : MyRec;
  otherRec : Record
    a : Integer;
    s : String;
    rec : MyRec;
    AlsoRec : Record
      m, n : Integer;
    End;
  End;

Begin
End.
