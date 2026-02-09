(* Test 10 - Standard Routines
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE colors
      T:TYPE-ENUMERATION
        D:DECL-TYPE red
          E:EXPR-WORD-LITERAL 0
        D:DECL-TYPE green
          E:EXPR-WORD-LITERAL 1
        D:DECL-TYPE blue
          E:EXPR-WORD-LITERAL 2
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-VARIABLE s
      T:TYPE-SHORTINT
    D:DECL-VARIABLE l
      T:TYPE-LONGINT
    D:DECL-VARIABLE r
      T:TYPE-REAL
    D:DECL-VARIABLE ch
      T:TYPE-CHARACTER
    D:DECL-VARIABLE b
      T:TYPE-BYTE
    D:DECL-VARIABLE w
      T:TYPE-WORD
    D:DECL-VARIABLE dw
      T:TYPE-CARDINAL
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-CALL T:TYPE-INTEGER
          Left:EXPR-NAME abs T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-WORD-LITERAL 3039 T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-SHORTINT
        Left:EXPR-NAME s T:TYPE-SHORTINT
        Right:EXPR-CALL T:TYPE-SHORTINT
          Left:EXPR-NAME abs T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-BYTE-LITERAL 7b T:TYPE-SHORTINT
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-LONGINT
        Left:EXPR-NAME l T:TYPE-LONGINT
        Right:EXPR-CALL T:TYPE-LONGINT
          Left:EXPR-NAME abs T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-DWORD-LITERAL 1e240 T:TYPE-LONGINT
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-REAL
        Left:EXPR-NAME r T:TYPE-REAL
        Right:EXPR-CALL T:TYPE-REAL
          Left:EXPR-NAME abs T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-REAL-LITERAL 3.14 T:TYPE-REAL
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-CALL T:TYPE-INTEGER
          Left:EXPR-NAME pred T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-WORD-LITERAL 3039 T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-CHARACTER
        Left:EXPR-NAME ch T:TYPE-CHARACTER
        Right:EXPR-CALL T:TYPE-CHARACTER
          Left:EXPR-NAME pred T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-CHARACTER-LITERAL 'c' T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-CALL T:TYPE-INTEGER
          Left:EXPR-NAME ord T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-NAME green T:TYPE-ENUMERATION-VALUE
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-CALL T:TYPE-INTEGER
          Left:EXPR-NAME ord T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-CHARACTER-LITERAL 'c' T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-CALL T:TYPE-INTEGER
          Left:EXPR-NAME ord T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-NAME i T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-CALL T:TYPE-INTEGER
          Left:EXPR-NAME trunc T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-REAL-LITERAL 3.14 T:TYPE-REAL
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME dec T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME i T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME dec T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME i T:TYPE-INTEGER
          EXPR-BYTE-LITERAL 2 T:TYPE-SHORTINT
*)

Program Test;

Type
  Colors = (Red, Green, Blue);

Var
  i : Integer;
  s : ShortInt;
  l : LongInt;
  r : Real;
  ch : Char;
  b : Byte;
  w : Word;
  dw : Cardinal;

Begin
  i := Abs(12345);
  s := Abs(123);
  l := Abs(123456);
  r := Abs(3.14);

  i := Pred(12345);
  ch := Pred('c');

  i := Ord(Green);
  i := Ord('c');
  i := Ord(i);

  i := Trunc(3.14);

  Dec(i);
  Dec(i, 2);
End.
