(* Test 4 - Constants
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-CONST boolconst
      T:TYPE-BOOLEAN
      E:EXPR-BOOLEAN-LITERAL true
    D:DECL-CONST charconst
      T:TYPE-CHARACTER
      E:EXPR-CHARACTER-LITERAL 'k'
    D:DECL-CONST strconst
      T:TYPE-STRING-VAR
      E:EXPR-STRING-LITERAL Hello World
    D:DECL-CONST byteconst
      T:TYPE-BYTE
      E:EXPR-BYTE-LITERAL c9
    D:DECL-CONST shortconst
      T:TYPE-SHORTINT
      E:EXPR-BYTE-LITERAL -7b
    D:DECL-CONST intconst
      T:TYPE-INTEGER
      E:EXPR-WORD-LITERAL -3039
    D:DECL-CONST wordconst
      T:TYPE-WORD
      E:EXPR-WORD-LITERAL b26e
    D:DECL-CONST longconst
      T:TYPE-LONGINT
      E:EXPR-DWORD-LITERAL -1e240
    D:DECL-CONST cardinalconst
      T:TYPE-CARDINAL
      E:EXPR-DWORD-LITERAL bc614e
    D:DECL-CONST realconst
      T:TYPE-REAL
      E:EXPR-REAL-LITERAL 123.456
*)

Program Test;

Const
    BoolConst = True;
    CharConst = 'k';
    StrConst = 'Hello World';
    ByteConst = 201;
    ShortConst = -123;
    IntConst = -12345;
    WordConst = 45678;
    LongConst = -123456;
    CardinalConst = 12345678;
    RealConst = 123.456;

Begin
End.
