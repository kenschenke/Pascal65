(* Test 4 - Constants
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-CONST myint
      T:TYPE-WORD
      E:EXPR-WORD-LITERAL 3039
    D:DECL-CONST pi
      T:TYPE-REAL
      E:EXPR-REAL-LITERAL 3.14159
    D:DECL-CONST greeting
      T:TYPE-STRING-VAR
      E:EXPR-STRING-LITERAL Hello World
*)

Program Test;

Const
  MyInt = 12345;
  Pi = 3.14159;
  Greeting = 'Hello World';

Begin
End.
