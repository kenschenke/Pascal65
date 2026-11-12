// Resolver Error Test 26
// A function declared forward, in a procedure, that has no body

Program Test;

Var
    i : Integer;

Procedure P;
    Function F(n : Integer) : Integer; Forward;  // Error
Begin
    i := 1;
End;

Begin
    P;
End.
