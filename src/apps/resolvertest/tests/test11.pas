(* Test 11 - Array Index Types
decl test 
  symtab
    a1 SYMBOL-GLOBAL L:1 O:4 TYPE-ARRAY S:12
    a2 SYMBOL-GLOBAL L:1 O:5 TYPE-ARRAY S:16
    a3 SYMBOL-GLOBAL L:1 O:6 TYPE-ARRAY S:26
    a4 SYMBOL-GLOBAL L:1 O:7 TYPE-ARRAY S:306
    a5 SYMBOL-GLOBAL L:1 O:8 TYPE-ARRAY S:17
    a6 SYMBOL-GLOBAL L:1 O:9 TYPE-ARRAY S:107
    a7 SYMBOL-GLOBAL L:1 O:10 TYPE-ARRAY S:20
    a8 SYMBOL-GLOBAL L:1 O:11 TYPE-ARRAY S:304
    a9 SYMBOL-GLOBAL L:1 O:12 TYPE-ARRAY S:9
    blue SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    c1 SYMBOL-GLOBAL L:1 O:13 TYPE-DECLARED S:2
    c2 SYMBOL-GLOBAL L:1 O:14 TYPE-DECLARED S:2
    color SYMBOL-GLOBAL L:1 O:0 TYPE-ENUMERATION S:2
    colorrec SYMBOL-GLOBAL L:1 O:0 TYPE-RECORD S:4
    cr SYMBOL-GLOBAL L:1 O:17 TYPE-RECORD S:4
    dir SYMBOL-GLOBAL L:1 O:16 TYPE-ENUMERATION S:2
    down SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    green SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    idx SYMBOL-GLOBAL L:1 O:0 TYPE-SUBRANGE S:1
    lo SYMBOL-GLOBAL L:1 O:2 TYPE-SHORTINT S:1
    m SYMBOL-GLOBAL L:1 O:1 TYPE-WORD S:2
    n SYMBOL-GLOBAL L:1 O:0 TYPE-BYTE S:1
    negm SYMBOL-GLOBAL L:1 O:3 TYPE-INTEGER S:2
    red SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    s1 SYMBOL-GLOBAL L:1 O:15 TYPE-DECLARED S:2
    shade SYMBOL-GLOBAL L:1 O:0 TYPE-DECLARED S:2
    up SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
  decl n L:1 O:0 TYPE-BYTE S:1
  decl m L:1 O:1 TYPE-WORD S:2
  decl lo L:1 O:2 TYPE-SHORTINT S:1
  decl negm L:1 O:3 TYPE-INTEGER S:2
  decl color L:1 O:0 TYPE-ENUMERATION S:2
  decl idx L:1 O:0 TYPE-SUBRANGE S:1
  decl shade L:1 O:0 TYPE-ENUMERATION S:2
  decl colorrec L:1 O:0 TYPE-RECORD S:4
    symtab
      c SYMBOL-GLOBAL L:0 O:0 TYPE-DECLARED S:2
      s SYMBOL-GLOBAL L:0 O:2 TYPE-DECLARED S:2
  decl a1 L:1 O:4 TYPE-ARRAY S:12
  decl a2 L:1 O:5 TYPE-ARRAY S:16
  decl a3 L:1 O:6 TYPE-ARRAY S:26
  decl a4 L:1 O:7 TYPE-ARRAY S:306
  decl a5 L:1 O:8 TYPE-ARRAY S:17
  decl a6 L:1 O:9 TYPE-ARRAY S:107
  decl a7 L:1 O:10 TYPE-ARRAY S:20
  decl a8 L:1 O:11 TYPE-ARRAY S:304
  decl a9 L:1 O:12 TYPE-ARRAY S:9
  decl c1 L:1 O:13 TYPE-ENUMERATION S:2
  decl c2 L:1 O:14 TYPE-ENUMERATION S:2
  decl s1 L:1 O:15 TYPE-DECLARED S:2
  decl dir L:1 O:16 TYPE-ENUMERATION S:2
  decl cr L:1 O:17 TYPE-RECORD S:4
    symtab
      c SYMBOL-GLOBAL L:0 O:0 TYPE-DECLARED S:2
      s SYMBOL-GLOBAL L:0 O:2 TYPE-DECLARED S:2
*)

// An array's index type can be a declared subrange or enumeration, a
// constant (the number of elements), or a subrange with negative or
// constant limits. Enumerations can be renamed and written in place.

Program Test;

Const
  N = 10;
  M = 300;
  Lo = -3;
  NegM = -300;

Type
  Color = (Red, Green, Blue);
  Idx = 1..10;
  Shade = Color;
  ColorRec = Record
    c : Color;
    s : Shade;
  End;

Var
  a1 : Array[Color] Of Integer;
  a2 : Array[Idx] Of Byte;
  a3 : Array[N] Of Integer;
  a4 : Array[M] Of Byte;
  a5 : Array[-5..5] Of Byte;
  a6 : Array[-300..-200] Of Byte;
  a7 : Array[Lo..N] Of Byte;
  a8 : Array[NegM..Lo] Of Byte;
  a9 : Array[Red..Blue] Of Byte;
  c1, c2 : Color;
  s1 : Shade;
  dir : (Up, Down);
  cr : ColorRec;

Begin
  a1[Green] := 1;
  c1 := Blue;
End.
