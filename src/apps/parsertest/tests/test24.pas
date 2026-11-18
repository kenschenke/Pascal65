(* Test 24 - A unit interface that ends with Type
D:DECL-TYPE test
  T:TYPE-UNIT
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE myenum
      T:TYPE-ENUMERATION
        D:DECL-TYPE one
          E:EXPR-WORD-LITERAL 0
        D:DECL-TYPE two
          E:EXPR-WORD-LITERAL 1
    D:DECL-VARIABLE hidden
      T:TYPE-INTEGER
*)

// Like test 22, with a Type section last in the interface.

Unit Test;

Interface

Type
  MyEnum = (One, Two);

Implementation

Var
  Hidden : Integer;

End.
