(* Test 18 - Type Casting
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE number
      T:TYPE-SHORTINT
    D:DECL-VARIABLE a
      T:TYPE-SHORTINT
    D:DECL-VARIABLE b
      T:TYPE-BYTE
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-VARIABLE w
      T:TYPE-WORD
    D:DECL-VARIABLE l
      T:TYPE-LONGINT
    D:DECL-VARIABLE c
      T:TYPE-CARDINAL
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-SHORTINT
        Left:EXPR-NAME a T:TYPE-SHORTINT
        Right:EXPR-TYPE-CAST T:TYPE-SHORTINT
          Left:EXPR-BYTE-LITERAL c8 T:TYPE-BYTE
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BYTE
        Left:EXPR-NAME b T:TYPE-BYTE
        Right:EXPR-TYPE-CAST T:TYPE-BYTE
          Left:EXPR-BYTE-LITERAL -7b T:TYPE-SHORTINT
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-TYPE-CAST T:TYPE-INTEGER
          Left:EXPR-WORD-LITERAL 9c40 T:TYPE-WORD
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-WORD
        Left:EXPR-NAME w T:TYPE-WORD
        Right:EXPR-TYPE-CAST T:TYPE-WORD
          Left:EXPR-WORD-LITERAL -3039 T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-LONGINT
        Left:EXPR-NAME l T:TYPE-LONGINT
        Right:EXPR-TYPE-CAST T:TYPE-LONGINT
          Left:EXPR-DWORD-LITERAL ffff0000 T:TYPE-CARDINAL
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-CARDINAL
        Left:EXPR-NAME c T:TYPE-CARDINAL
        Right:EXPR-TYPE-CAST T:TYPE-CARDINAL
          Left:EXPR-DWORD-LITERAL -1e240 T:TYPE-LONGINT
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-SHORTINT
        Left:EXPR-NAME a T:TYPE-SHORTINT
        Right:EXPR-TYPE-CAST T:TYPE-SHORTINT
          Left:EXPR-BYTE-LITERAL c8 T:TYPE-BYTE
*)

Program Test;

Type
  Number = ShortInt;

Var
  a : ShortInt;
  b : Byte;
  i : Integer;
  w : Word;
  l : LongInt;
  c : Cardinal;

Begin
  a := ShortInt(200);
  b := Byte(-123);
  i := Integer(40000);
  w := Word(-12345);
  l := LongInt($ffff0000);
  c := Cardinal(-123456);

  // Type cast with a declared type
  a := Number(200);
End.
