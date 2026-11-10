// Error Test 11 - Errors and warnings are reported in their own file.
// errunit.pas has the same errors and warnings on the same lines.

Program TestUnitErrors;

Uses ErrUnit;

// Without the filename, the second report of each error or warning
// would match the expectation the first one already used, and the test
// would fail.

// Resolver error
Procedure MainP; Var a : Byte; a : Byte; Begin (* $ExpectError 28 *) End;

Procedure MainProc;
Var
    b : Byte;
    r : Real;
Begin
    b := r;         (* $ExpectError 38 *)
    b := 12345;     (* $ExpectWarn 66 *)
End;

Begin
    MainProc;
    UnitProc;
End.
