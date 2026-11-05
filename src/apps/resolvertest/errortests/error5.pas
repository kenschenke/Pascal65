// Resolver Error Test 5
// A named dynamic array type as a field of a record variable

Program Test;

Type
    TDyn = Array Of Integer;

Var
    i : Integer;
    r : Record
        x : TDyn;                           // Error
    End;

Begin
End.
