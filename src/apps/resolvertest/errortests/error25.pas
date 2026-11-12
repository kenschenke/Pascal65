// Resolver Error Test 25
// A procedure declared forward that has no body

Program Test;

Var
    i : Integer;

Procedure P(n : Integer); Forward;   // Error

Begin
    i := 1;
End.
