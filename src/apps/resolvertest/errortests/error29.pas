// Resolver Error Test 29
// A record field of a type that isn't declared

Program Test;

Type
    Rec = Record
        a : Integer;
        b : NoSuchType;         // Error
    End;

Begin
End.
