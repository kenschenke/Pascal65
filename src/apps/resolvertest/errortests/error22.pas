// Resolver Error Test 22
// A field of a record variable that isn't declared. Only the record is
// reported.

Program Test;

Var
    r : Record
        a, b : Integer;
    End;

Begin
    q.a := 1;                   // Error
End.
