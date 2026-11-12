// Resolver Error Test 21
// A record field that isn't declared

Program Test;

Var
    r : Record
        a, b : Integer;
    End;

Begin
    r.c := 1;                   // Error
End.
