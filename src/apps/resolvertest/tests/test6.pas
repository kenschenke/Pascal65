(* Test 6 - Functions and Procedures
decl test L:0 O:0 TYPE-PROGRAM S:0
  symtab
    myfunc SYMBOL-GLOBAL L:2 O:0 TYPE-FUNCTION S:2
    myproc SYMBOL-GLOBAL L:2 O:0 TYPE-PROCEDURE S:0
  decl myproc L:2 O:0 TYPE-PROCEDURE S:0
    symtab
      a SYMBOL-LOCAL L:2 O:0 TYPE-INTEGER S:2
      b SYMBOL-LOCAL L:2 O:1 TYPE-INTEGER S:2
      innerproc SYMBOL-LOCAL L:3 O:0 TYPE-PROCEDURE S:0
      k SYMBOL-LOCAL L:2 O:6 TYPE-BOOLEAN S:1
      m SYMBOL-LOCAL L:2 O:5 TYPE-INTEGER S:2
      n SYMBOL-LOCAL L:2 O:4 TYPE-INTEGER S:2
      r SYMBOL-LOCAL L:2 O:2 TYPE-REAL S:4
      x SYMBOL-LOCAL L:2 O:3 TYPE-STRING-VAR S:2
    decl n L:2 O:4 TYPE-INTEGER S:2
    decl m L:2 O:5 TYPE-INTEGER S:2
    decl k L:2 O:6 TYPE-BOOLEAN S:1
    decl innerproc L:3 O:0 TYPE-PROCEDURE S:0
      symtab
        o SYMBOL-LOCAL L:3 O:0 TYPE-INTEGER S:2
        p SYMBOL-LOCAL L:3 O:1 TYPE-INTEGER S:2
        x SYMBOL-LOCAL L:3 O:2 TYPE-WORD S:2
      decl x L:3 O:2 TYPE-WORD S:2
  decl myfunc L:2 O:0 TYPE-FUNCTION S:2
    symtab
      b SYMBOL-LOCAL L:2 O:0 TYPE-BOOLEAN S:1
      j SYMBOL-LOCAL L:2 O:1 TYPE-INTEGER S:2
      myfunc SYMBOL-LOCAL L:2 O:5 TYPE-STRING-VAR S:2
      r SYMBOL-LOCAL L:2 O:2 TYPE-REAL S:4
      s SYMBOL-LOCAL L:2 O:3 TYPE-STRING-VAR S:2
      t SYMBOL-LOCAL L:2 O:4 TYPE-STRING-VAR S:2
    decl r L:2 O:2 TYPE-REAL S:4
    decl s L:2 O:3 TYPE-STRING-VAR S:2
    decl t L:2 O:4 TYPE-STRING-VAR S:2
    decl myfunc L:2 O:5 TYPE-STRING-VAR S:2
*)

Program Test;

Procedure MyProc(a, b : Integer; Var r : Real; x : String);
Var
  n, m : Integer;
  k : Boolean;

  Procedure InnerProc(o, p : Integer);
  Var
    x : Word;
  Begin
  End;

Begin
End;

Function MyFunc(b : Boolean; j : Integer) : String;
Var
  r : Real;
  s, t : String;
Begin
End;

Begin
End.
