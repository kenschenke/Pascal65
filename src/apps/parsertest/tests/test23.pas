(* Test 23 - A unit interface that ends with Const
D:DECL-TYPE test
  T:TYPE-UNIT
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-CONST two
      T:TYPE-BYTE
      E:EXPR-BYTE-LITERAL 2
    D:DECL-VARIABLE hidden
      T:TYPE-INTEGER
*)

// Like test 22, with a Const section last in the interface.

Unit Test;

Interface

Const
  Two = 2;

Implementation

Var
  Hidden : Integer;

End.
