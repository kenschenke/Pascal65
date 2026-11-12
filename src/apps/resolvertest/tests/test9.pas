(* Test 9 - Subranges
decl test 
  symtab
    a SYMBOL-GLOBAL L:1 O:3 TYPE-SUBRANGE S:2
    b SYMBOL-GLOBAL L:1 O:4 TYPE-SUBRANGE S:1
    blue SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    c SYMBOL-GLOBAL L:1 O:5 TYPE-SUBRANGE S:2
    ch SYMBOL-GLOBAL L:1 O:2 TYPE-CHARACTER S:1
    color SYMBOL-GLOBAL L:1 O:0 TYPE-ENUMERATION S:2
    d SYMBOL-GLOBAL L:1 O:6 TYPE-SUBRANGE S:4
    e SYMBOL-GLOBAL L:1 O:7 TYPE-SUBRANGE S:4
    f SYMBOL-GLOBAL L:1 O:8 TYPE-SUBRANGE S:2
    g SYMBOL-GLOBAL L:1 O:9 TYPE-SUBRANGE S:2
    green SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:0
    hi SYMBOL-GLOBAL L:1 O:1 TYPE-WORD S:2
    k SYMBOL-GLOBAL L:1 O:10 TYPE-SUBRANGE S:1
    lo SYMBOL-GLOBAL L:1 O:0 TYPE-BYTE S:1
    m SYMBOL-GLOBAL L:1 O:11 TYPE-SUBRANGE S:2
    red SYMBOL-LOCAL L:0 O:0 TYPE-ENUMERATION-VALUE S:2
  decl lo L:1 O:0 TYPE-BYTE S:1
  decl hi L:1 O:1 TYPE-WORD S:2
  decl ch L:1 O:2 TYPE-CHARACTER S:1
  decl color L:1 O:0 TYPE-ENUMERATION S:2
  decl a L:1 O:3 TYPE-SUBRANGE S:2
  decl b L:1 O:4 TYPE-SUBRANGE S:1
  decl c L:1 O:5 TYPE-SUBRANGE S:2
  decl d L:1 O:6 TYPE-SUBRANGE S:4
  decl e L:1 O:7 TYPE-SUBRANGE S:4
  decl f L:1 O:8 TYPE-SUBRANGE S:2
  decl g L:1 O:9 TYPE-SUBRANGE S:2
  decl k L:1 O:10 TYPE-SUBRANGE S:1
  decl m L:1 O:11 TYPE-SUBRANGE S:2
*)

// A subrange's limits can be integers of different types, constants or
// enumeration values. Its size is the size of the integer type that holds
// both limits.

Program Test;

Const
  Lo = 1;
  Hi = 1000;
  Ch = 'a';

Type
  Color = (Red, Green, Blue);

Var
  a : 1..1000;
  b : -5..5;
  c : -1000..5;
  d : 1..100000;
  e : -5..100000;
  f : Lo..Hi;
  g : 0..Hi;
  k : Ch..'z';
  m : Red..Blue;

Begin
End.
