(* Test 16 - Type casts
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE number
      T:TYPE-INTEGER
    D:DECL-VARIABLE b
      T:TYPE-BYTE
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME b
        Right:EXPR-TYPE-CAST T:TYPE-BYTE
          Left:EXPR-NAME i
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-TYPE-CAST T:TYPE-INTEGER
          Left:EXPR-NAME b
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-ADD
          Left:EXPR-TYPE-CAST T:TYPE-INTEGER
            Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL c8
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-CALL
          Left:EXPR-NAME number
          Right:EXPR-ARG
            EXPR-NAME b
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-TYPE-CAST T:TYPE-INTEGER
          Left:EXPR-SUB
            Left:EXPR-BYTE-LITERAL c8
            Right:EXPR-BYTE-LITERAL 5
*)

Program Test;

Type
  Number = Integer;

Var
    b : Byte;
    i : Integer;

Begin
    b := Byte(i);
    i := Integer(b);
    i := Integer(b) + 200;
    i := Number(b);
    i := Integer(200 - 5);
End.
