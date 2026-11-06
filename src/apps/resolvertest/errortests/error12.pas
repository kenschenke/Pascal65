// Resolver Error Test 12
// A routine declared forward twice. Its body still resolves.

Program Test;

Var
    i : Integer;

Procedure P(n : Integer); Forward;
Procedure P(n : Integer); Forward;          // Error

Procedure P(n : Integer);
Begin
    i := n;
End;

Begin
    P(1);
End.
