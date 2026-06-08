(* Test 3 - Constants
decl test 
  symtab
    greeting SYMBOL-GLOBAL L:1 O:2 TYPE-STRING-VAR S:2
    myint SYMBOL-GLOBAL L:1 O:0 TYPE-WORD S:2
    pi SYMBOL-GLOBAL L:1 O:1 TYPE-REAL S:4
  decl myint L:1 O:0 TYPE-WORD S:2
  decl pi L:1 O:1 TYPE-REAL S:4
  decl greeting L:1 O:2 TYPE-STRING-VAR S:2
*)

Program Test;

Const
  MyInt = 12345;
  Pi = 3.14159;
  Greeting = 'Hello World';

Begin
End.
