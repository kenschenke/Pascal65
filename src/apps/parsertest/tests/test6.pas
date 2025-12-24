(* Test 6 - If-Then Statements
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
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL Small
    S:STMT-IF-ELSE
      E:EXPR-AND
        Left:EXPR-GT
          Left:EXPR-NAME i
          Right:EXPR-BYTE-LITERAL 5
        Right:EXPR-LT
          Left:EXPR-NAME i
          Right:EXPR-BYTE-LITERAL 64
      If True:
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL Medium
    S:STMT-IF-ELSE
      E:EXPR-GTE
        Left:EXPR-NAME i
        Right:EXPR-WORD-LITERAL 3e8
      If True:
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL Multiple statements
        S:STMT-EXPR
          E:EXPR-ASSIGN
            Left:EXPR-NAME i
            Right:EXPR-WORD-LITERAL 7d0
    S:STMT-IF-ELSE
      E:EXPR-GTE
        Left:EXPR-NAME i
        Right:EXPR-WORD-LITERAL 2710
      If True:
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL Really big
      If False:
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL Maybe big
    S:STMT-IF-ELSE
      E:EXPR-EQ
        Left:EXPR-MOD
          Left:EXPR-NAME i
          Right:EXPR-BYTE-LITERAL 2
        Right:EXPR-BYTE-LITERAL 0
      If True:
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL Even
      If False:
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL Odd
        S:STMT-EXPR
          E:EXPR-ASSIGN
            Left:EXPR-NAME i
            Right:EXPR-MUL
              Left:EXPR-NAME i
              Right:EXPR-BYTE-LITERAL 5
*)

Program Test;

Var
    i : Integer;

Begin
  If i < 5 Then Writeln('Small');
  If (i > 5) And (i < 100) Then Writeln('Medium');
  If (i >= 1000) Then Begin
    Writeln('Multiple statements');
    i := 2000;
  End;
  If (i >= 10000) Then
    Writeln('Really big')
  Else
    Writeln('Maybe big');
  If i Mod 2 = 0 Then
    Writeln('Even')
  Else Begin
    Writeln('Odd');
    i := i * 5;
  End;
End.
