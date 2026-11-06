// Resolver Error Test 10
// A routine defined twice

Program Test;

Var
    i : Integer;

Procedure P;
Begin
    i := 1;
End;

Procedure P;                                // Error
Begin
    i := 2;
End;

Begin
    P;
End.
