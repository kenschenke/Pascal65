(* Test 15 - Case Statement
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-VARIABLE j
      T:TYPE-INTEGER
    S:STMT-CASE
      E:EXPR-NAME i T:TYPE-INTEGER
      S:STMT-CASE-LABEL
        EXPR-BYTE-LITERAL 1
        EXPR-BYTE-LITERAL 2
        EXPR-BYTE-LITERAL 3
        Case Body:
          S:STMT-EXPR
            E:EXPR-CALL
              Left:EXPR-NAME writeln
              Right:EXPR-ARG
                EXPR-STRING-LITERAL First three
      S:STMT-CASE-LABEL
        EXPR-BYTE-LITERAL 4
        EXPR-BYTE-LITERAL 5
        Case Body:
          S:STMT-EXPR
            E:EXPR-CALL
              Left:EXPR-NAME writeln
              Right:EXPR-ARG
                EXPR-STRING-LITERAL 4 and 5
          S:STMT-EXPR
            E:EXPR-ASSIGN
              Left:EXPR-NAME j
              Right:EXPR-BYTE-LITERAL a
      S:STMT-CASE-LABEL
        EXPR-BYTE-LITERAL 6
        Case Body:
          S:STMT-EXPR
            E:EXPR-CALL
              Left:EXPR-NAME write
              Right:EXPR-ARG
                EXPR-STRING-LITERAL Six
*)

Program Test;

Var
  i, j : Integer;

Begin
  Case i Of
    1, 2, 3: Writeln('First three');
    4, 5: Begin
      Writeln('4 and 5');
      j := 10;
    End;
    6: Write('Six');
  End;
End.
