(* Test 5 - Initial Values
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE a
      T:TYPE-SHORTINT
      E:EXPR-BYTE-LITERAL 7b
    D:DECL-VARIABLE ch
      T:TYPE-CHARACTER
      E:EXPR-CHARACTER-LITERAL 'k'
    D:DECL-VARIABLE card
      T:TYPE-CARDINAL
      E:EXPR-DWORD-LITERAL 1e240
    D:DECL-VARIABLE b
      T:TYPE-BYTE
      E:EXPR-BYTE-LITERAL ea
    D:DECL-VARIABLE bool
      T:TYPE-BOOLEAN
      E:EXPR-BOOLEAN-LITERAL true
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
      E:EXPR-WORD-LITERAL 3039
    D:DECL-VARIABLE l
      T:TYPE-LONGINT
      E:EXPR-DWORD-LITERAL 12d687
    D:DECL-VARIABLE r
      T:TYPE-REAL
      E:EXPR-REAL-LITERAL 3.14159
    D:DECL-VARIABLE w
      T:TYPE-WORD
      E:EXPR-WORD-LITERAL 8707
    D:DECL-VARIABLE str
      T:TYPE-STRING-VAR
      E:EXPR-STRING-LITERAL Hello World
    D:DECL-VARIABLE arr
      T:TYPE-ARRAY  1.. 5 OF TYPE-BYTE
      E:EXPR-ARRAY-LITERAL
        EXPR-BYTE-LITERAL 1
        EXPR-BYTE-LITERAL 2
        EXPR-BYTE-LITERAL 3
*)

Program Test;

Var
    a : ShortInt = 123;
    ch : Char = 'k';
    card : Cardinal = 123456;
    b : Byte = 234;
    bool : Boolean = True;
    i : Integer = 12345;
    l : LongInt = 1234567;
    r : Real = 3.14159;
    w : Word = 34567;
    str : String = 'Hello World';
    arr : Array[1..5] Of Byte = (1, 2, 3);

Begin
End.
