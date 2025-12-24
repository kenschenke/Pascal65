(* Test 7 - Loops
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    S:STMT-WHILE
      E:EXPR-LT
        Left:EXPR-NAME i
        Right:EXPR-BYTE-LITERAL 5
      S:STMT-EXPR
        E:EXPR-CALL
          Left:EXPR-NAME writeln
          Right:EXPR-ARG
            EXPR-STRING-LITERAL i = 
            EXPR-NAME i
      S:STMT-EXPR
        E:EXPR-CALL
          Left:EXPR-NAME inc
          Right:EXPR-ARG
            EXPR-NAME i
    S:STMT-REPEAT
      E:EXPR-EQ
        Left:EXPR-NAME i
        Right:EXPR-BYTE-LITERAL a
      S:STMT-EXPR
        E:EXPR-CALL
          Left:EXPR-NAME writeln
          Right:EXPR-ARG
            EXPR-STRING-LITERAL i = 
            EXPR-NAME i
      S:STMT-EXPR
        E:EXPR-CALL
          Left:EXPR-NAME inc
          Right:EXPR-ARG
            EXPR-NAME i
    S:STMT-FOR
      Init:
        E:EXPR-ASSIGN
          Left:EXPR-NAME i
          Right:EXPR-BYTE-LITERAL 1
      To:
        E:EXPR-BYTE-LITERAL 5
      DownTo: No
      S:STMT-EXPR
        E:EXPR-CALL
          Left:EXPR-NAME writeln
          Right:EXPR-ARG
            EXPR-STRING-LITERAL i = 
            EXPR-NAME i
    S:STMT-FOR
      Init:
        E:EXPR-ASSIGN
          Left:EXPR-NAME i
          Right:EXPR-BYTE-LITERAL 5
      To:
        E:EXPR-BYTE-LITERAL 1
      DownTo: Yes
      S:STMT-EXPR
        E:EXPR-CALL
          Left:EXPR-NAME writeln
          Right:EXPR-ARG
            EXPR-STRING-LITERAL i = 
            EXPR-NAME i
      S:STMT-EXPR
        E:EXPR-ASSIGN
          Left:EXPR-NAME j
          Right:EXPR-MUL
            Left:EXPR-NAME i
            Right:EXPR-BYTE-LITERAL 5
*)

Program Test;

Var
    i : Integer;

Begin
  While i < 5 Do Begin
    Writeln('i = ', i);
    Inc(i);
  End;

  Repeat
    Writeln('i = ', i);
    Inc(i);
  Until i = 10;

  For i := 1 To 5 Do
    Writeln('i = ', i);
  
  For i := 5 DownTo 1 Do Begin
    Writeln('i = ', i);
    j := i * 5;
  End;
End.
