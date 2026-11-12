// Resolver Error Test 43
// A field, of a type that isn't declared, of a record written in an
// array declaration

Program Test;

Var
    a : Array[1..3] Of Record
        i : Integer;
        x : NoSuchType;         // Error
    End;

Begin
End.
