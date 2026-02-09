(* Test 14 - Pass by reference
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE r
      T:TYPE-REAL
    D:DECL-TYPE myproc
      T:TYPE-PROCEDURE
        param: i
          T:TYPE-INTEGER
        param: r
          T:TYPE-REAL
          flags: TYPE-FLAG-ISBYREF
        param: ch
          T:TYPE-CHARACTER
      S:STMT-BLOCK
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME myproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-WORD-LITERAL 3039 T:TYPE-INTEGER
          EXPR-NAME r T:TYPE-REAL
          EXPR-CHARACTER-LITERAL 'x' T:TYPE-CHARACTER
*)

Program Test;

Var
  r : Real;

Procedure MyProc(i : Integer; Var r : Real; ch : Char);
Begin
End;

Begin
  MyProc(12345, r, 'x');
End.
