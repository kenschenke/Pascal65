// Resolver Error Test 8
// A variable redefined in the same scope. Names in other scopes are fine.

Program Test;

Var
    a : Integer;
    b : Integer;

Procedure P(b : Char);
Var
    a : Char;

    Procedure P;
    Var
        a : Boolean;
    Begin
    End;

Begin
End;

Var
    a : Char;                               // Error

Begin
End.
