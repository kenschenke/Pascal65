(* Test 12 - Read, Readln, Readstr
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
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME read T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME i T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME readln T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME i T:TYPE-INTEGER
          EXPR-NAME ch T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME readln T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME arr T:TYPE-ARRAY
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME readln T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME str T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME read T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME fh T:TYPE-FILE
          EXPR-NAME i T:TYPE-INTEGER
*)

Program Test;

Var
  i : Integer;
  ch : Char;
  arr : Array[1..10] Of Char;
  str : String;
  fh : File Of Integer;

Begin
  Read(i);
  Readln(i, ch);
  Readln(arr);
  Readln(str);
  Read(fh, i);
End.
