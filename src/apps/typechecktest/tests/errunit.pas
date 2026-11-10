// Unit for Error Test 11. Its errors and warnings are on the same lines
// as error11.pas's, so each only matches if it's reported in this file.

Unit ErrUnit;

Interface

Procedure UnitProc;

Implementation

// Resolver error
Procedure UnitP; Var a : Byte; a : Byte; Begin (* $ExpectError 28 *) End;

Procedure UnitProc;
Var
    b : Byte;
    r : Real;
Begin
    b := r;         (* $ExpectError 38 *)
    b := 12345;     (* $ExpectWarn 66 *)
End;

End.
