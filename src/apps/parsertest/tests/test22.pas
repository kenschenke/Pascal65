(* Test 22 - A unit interface that ends with Var
D:DECL-TYPE test
  T:TYPE-UNIT
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE count
      T:TYPE-INTEGER
    D:DECL-VARIABLE hidden
      T:TYPE-INTEGER
*)

// An interface or an implementation may have no routines. The Var
// section's resync once skipped Implementation and End and reported
// errUnexpectedToken.

Unit Test;

Interface

Var
  Count : Integer;

Implementation

Var
  Hidden : Integer;

End.
