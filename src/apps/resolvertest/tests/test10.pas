(* Test 10 - Statements and Expressions
decl test 
  symtab
    fact SYMBOL-GLOBAL L:2 O:0 TYPE-FUNCTION S:2
    i SYMBOL-GLOBAL L:1 O:0 TYPE-INTEGER S:2
    innerrec SYMBOL-GLOBAL L:1 O:0 TYPE-RECORD S:4
    j SYMBOL-GLOBAL L:1 O:1 TYPE-INTEGER S:2
    outer SYMBOL-GLOBAL L:1 O:3 TYPE-RECORD S:26
    outerrec SYMBOL-GLOBAL L:1 O:0 TYPE-RECORD S:26
    outers SYMBOL-GLOBAL L:1 O:4 TYPE-ARRAY S:58
    parr SYMBOL-GLOBAL L:1 O:8 TYPE-ARRAY S:14
    pi SYMBOL-GLOBAL L:1 O:5 TYPE-POINTER S:4
    pinner SYMBOL-GLOBAL L:1 O:0 TYPE-POINTER S:4
    pouter SYMBOL-GLOBAL L:1 O:7 TYPE-POINTER S:26
    ppi SYMBOL-GLOBAL L:1 O:6 TYPE-POINTER S:4
    ppinner SYMBOL-GLOBAL L:1 O:0 TYPE-POINTER S:4
    r SYMBOL-GLOBAL L:1 O:2 TYPE-REAL S:4
    twice SYMBOL-GLOBAL L:2 O:0 TYPE-FUNCTION S:2
  decl innerrec L:1 O:0 TYPE-RECORD S:4
    symtab
      x SYMBOL-GLOBAL L:0 O:0 TYPE-INTEGER S:2
      y SYMBOL-GLOBAL L:0 O:2 TYPE-INTEGER S:2
  decl outerrec L:1 O:0 TYPE-RECORD S:26
    symtab
      inner SYMBOL-GLOBAL L:0 O:0 TYPE-RECORD S:4
      items SYMBOL-GLOBAL L:0 O:4 TYPE-ARRAY S:18
      pin SYMBOL-GLOBAL L:0 O:22 TYPE-POINTER S:4
  decl pinner L:1 O:0 TYPE-POINTER S:4
  decl ppinner L:1 O:0 TYPE-POINTER S:4
  decl i L:1 O:0 TYPE-INTEGER S:2
  decl j L:1 O:1 TYPE-INTEGER S:2
  decl r L:1 O:2 TYPE-REAL S:4
  decl outer L:1 O:3 TYPE-RECORD S:26
    symtab
      inner SYMBOL-GLOBAL L:0 O:0 TYPE-RECORD S:4
      items SYMBOL-GLOBAL L:0 O:4 TYPE-ARRAY S:18
      pin SYMBOL-GLOBAL L:0 O:22 TYPE-POINTER S:4
  decl outers L:1 O:4 TYPE-ARRAY S:58
  decl pi L:1 O:5 TYPE-POINTER S:4
  decl ppi L:1 O:6 TYPE-POINTER S:4
  decl pouter L:1 O:7 TYPE-POINTER S:26
  decl parr L:1 O:8 TYPE-ARRAY S:14
  decl fact L:2 O:0 TYPE-FUNCTION S:2
    symtab
      fact SYMBOL-LOCAL L:2 O:1 TYPE-INTEGER S:2
      n SYMBOL-LOCAL L:2 O:0 TYPE-INTEGER S:2
    decl fact L:2 O:1 TYPE-INTEGER S:2
  decl twice L:2 O:0 TYPE-FUNCTION S:2
  decl twice L:2 O:0 TYPE-FUNCTION S:2
    symtab
      n SYMBOL-LOCAL L:2 O:0 TYPE-INTEGER S:2
      twice SYMBOL-LOCAL L:2 O:1 TYPE-INTEGER S:2
    decl twice L:2 O:1 TYPE-INTEGER S:2
*)

// Names in statements: case labels, a recursive function, a function
// declared forward, write arguments with a field width, and fields of
// records reached through other fields, array elements and pointers.

Program Test;

Type
  InnerRec = Record
    x, y : Integer;
  End;
  OuterRec = Record
    inner : InnerRec;
    items : Array[1..3] Of InnerRec;
    pin : ^InnerRec;
  End;
  PInner = ^InnerRec;
  PPInner = ^PInner;

Var
  i, j : Integer;
  r : Real;
  outer : OuterRec;
  outers : Array[1..2] Of OuterRec;
  pi : PInner;
  ppi : PPInner;
  pouter : ^OuterRec;
  parr : Array[1..2] Of PInner;

Function Fact(n : Integer) : Integer;
Begin
  If n > 1 Then Fact := n * Fact(n - 1)
  Else Fact := 1;
End;

Function Twice(n : Integer) : Integer; Forward;

Function Twice(n : Integer) : Integer;
Begin
  Twice := n * 2;
End;

Begin
  Case i Of
    1, 2 : j := 1;
    3 : j := Fact(i);
  End;
  outer.inner.x := 1;
  outer.items[2].y := 2;
  outers[1].inner.x := 3;
  outers[2].items[3].y := 4;
  pi^.x := 5;
  ppi^^.y := 6;
  outer.pin^.x := 7;
  pouter^.inner.y := 8;
  pouter^.items[1].x := 9;
  parr[2]^.y := 10;
  Writeln(r:8:2, Twice(i));
End.
