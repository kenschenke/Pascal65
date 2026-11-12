// Resolver Error Test 24
// A field of an element of an array that isn't declared

Program Test;

Type
    Rec = Record
        a : Integer;
    End;

Var
    arr : Array[1..3] Of Rec;

Begin
    arx[1].a := 1;              // Error
End.
