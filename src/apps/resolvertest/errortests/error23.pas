// Resolver Error Test 23
// A field of a record field that isn't declared

Program Test;

Var
    r : Record
        a : Integer;
        inner : Record
            x : Integer;
        End;
    End;

Begin
    r.b.x := 1;                 // Error
End.
