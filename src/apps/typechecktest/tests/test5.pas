(* Test 5 - Routines
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE fr
      T:TYPE-REAL
    D:DECL-TYPE myproc
      T:TYPE-PROCEDURE
        param: i
          T:TYPE-INTEGER
        param: r
          T:TYPE-REAL
        param: ch
          T:TYPE-CHARACTER
      S:STMT-BLOCK
    D:DECL-TYPE myfunc
      T:TYPE-FUNCTION
        return: TYPE-REAL
        param: i
          T:TYPE-INTEGER
      S:STMT-BLOCK
        D:DECL-VARIABLE myfunc
          T:TYPE-REAL
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME myproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-WORD-LITERAL 3039 T:TYPE-INTEGER
          EXPR-REAL-LITERAL 3.14 T:TYPE-REAL
          EXPR-CHARACTER-LITERAL 'x' T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-REAL
        Left:EXPR-NAME fr T:TYPE-REAL
        Right:EXPR-CALL T:TYPE-REAL
          Left:EXPR-NAME myfunc T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-WORD-LITERAL 10e1 T:TYPE-INTEGER
*)

Program Test;

Var fr : Real;

Procedure MyProc(i : Integer; r : Real; ch : Char);
Begin
End;

Function MyFunc(i : Integer) : Real;
Begin
End;

Begin
  MyProc(12345, 3.14, 'x');
  fr := MyFunc(4321);
End.
