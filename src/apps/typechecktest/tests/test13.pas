(* Test 13 - Write, Writeln, Writestr
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-VARIABLE ch
      T:TYPE-CHARACTER
    D:DECL-VARIABLE arr
      T:TYPE-ARRAY  1.. a OF TYPE-CHARACTER
    D:DECL-VARIABLE str
      T:TYPE-STRING-VAR
    D:DECL-VARIABLE fh
      T:TYPE-FILE
        T:TYPE-INTEGER
    D:DECL-VARIABLE r
      T:TYPE-REAL
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME write T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME i T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME writeln T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME i T:TYPE-INTEGER
          EXPR-NAME ch T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME writeln T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME arr T:TYPE-ARRAY
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME writeln T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME str T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME writeln T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-STRING-LITERAL Hello, World T:TYPE-STRING-LITERAL
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME writeln T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-CHARACTER-LITERAL 'x' T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME write T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME fh T:TYPE-FILE
          EXPR-NAME i T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME writeln T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME r T:TYPE-REAL
*)

Program Test;

Var
  i : Integer;
  ch : Char;
  arr : Array[1..10] Of Char;
  str : String;
  fh : File Of Integer;
  r : Real;

Begin
  Write(i);
  Writeln(i, ch);
  Writeln(arr);
  Writeln(str);
  Writeln('Hello, World');
  Writeln('x');
  Write(fh, i);
  Writeln(r:6:2)
End.
