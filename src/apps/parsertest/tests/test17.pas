(* Test 17 - Declaration sections out of order and repeated
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE number
      T:TYPE-INTEGER
    D:DECL-CONST one
      T:TYPE-BYTE
      E:EXPR-BYTE-LITERAL 1
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-CONST two
      T:TYPE-BYTE
      E:EXPR-BYTE-LITERAL 2
    D:DECL-TYPE letter
      T:TYPE-CHARACTER
    D:DECL-TYPE myproc
      T:TYPE-PROCEDURE
      S:STMT-BLOCK
    D:DECL-VARIABLE b
      T:TYPE-BYTE
*)

// The Const, Type, Var and routine sections can come in any order and
// more than once.

Program Test;

Type
    Number = Integer;

Const
    One = 1;

Var
    i : Integer;

Const
    Two = 2;

Type
    Letter = Char;

Procedure MyProc;
Begin
End;

Var
    b : Byte;

Begin
End.
