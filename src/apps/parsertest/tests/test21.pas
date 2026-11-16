(* Test 21 - Calls with no arguments before End, Else and Until
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    S:STMT-IF-ELSE
      E:EXPR-LT
        Left:EXPR-NAME i
        Right:EXPR-BYTE-LITERAL 5
      If True:
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME foo
      If False:
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME bar
    S:STMT-WHILE
      E:EXPR-LT
        Left:EXPR-NAME i
        Right:EXPR-BYTE-LITERAL 5
      S:STMT-EXPR
        E:EXPR-CALL
          Left:EXPR-NAME foo
    S:STMT-REPEAT
      E:EXPR-EQ
        Left:EXPR-NAME i
        Right:EXPR-BYTE-LITERAL 5
      S:STMT-EXPR
        E:EXPR-CALL
          Left:EXPR-NAME foo
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME bar
*)

Program Test;

Var
    i : Integer;

Begin
  If i < 5 Then Foo Else Bar;
  While i < 5 Do Begin Foo End;
  Repeat Foo Until i = 5;
  Bar
End.
