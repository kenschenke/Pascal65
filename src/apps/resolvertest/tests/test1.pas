(* Test 1 - Scalar Variable Declarations
decl test L:0 O:0 TYPE-PROGRAM S:0
  symtab
    a SYMBOL-GLOBAL L:1 O:0 TYPE-SHORTINT S:1
    b SYMBOL-GLOBAL L:1 O:3 TYPE-BYTE S:1
    bool SYMBOL-GLOBAL L:1 O:4 TYPE-BOOLEAN S:1
    card SYMBOL-GLOBAL L:1 O:2 TYPE-CARDINAL S:4
    ch SYMBOL-GLOBAL L:1 O:1 TYPE-CHARACTER S:1
    fi SYMBOL-GLOBAL L:1 O:10 TYPE-FILE S:4
    ft SYMBOL-GLOBAL L:1 O:11 TYPE-TEXT S:4
    i SYMBOL-GLOBAL L:1 O:5 TYPE-INTEGER S:2
    j SYMBOL-GLOBAL L:1 O:6 TYPE-INTEGER S:2
    r SYMBOL-GLOBAL L:1 O:7 TYPE-REAL S:4
    str SYMBOL-GLOBAL L:1 O:9 TYPE-STRING-VAR S:2
    w SYMBOL-GLOBAL L:1 O:8 TYPE-WORD S:2
  decl a L:1 O:0 TYPE-SHORTINT S:1
  decl ch L:1 O:1 TYPE-CHARACTER S:1
  decl card L:1 O:2 TYPE-CARDINAL S:4
  decl b L:1 O:3 TYPE-BYTE S:1
  decl bool L:1 O:4 TYPE-BOOLEAN S:1
  decl i L:1 O:5 TYPE-INTEGER S:2
  decl j L:1 O:6 TYPE-INTEGER S:2
  decl r L:1 O:7 TYPE-REAL S:4
  decl w L:1 O:8 TYPE-WORD S:2
  decl str L:1 O:9 TYPE-STRING-VAR S:2
  decl fi L:1 O:10 TYPE-FILE S:4
  decl ft L:1 O:11 TYPE-TEXT S:4
*)

Program Test;

Var
    a : ShortInt;
    ch : Char;
    card : Cardinal;
    b : Byte;
    bool : Boolean;
    i, j : Integer;
    r : Real;
    w : Word;
    str : String;
    fi : File Of Integer;
    ft : Text;

Begin
End.
