// Resolver Error Test 7
// A named dynamic array type as a field of an anonymous record that is
// the element of a dynamic array type

Program Test;

Type
    TDyn = Array Of Integer;
    TArr = Array Of Record
        i : Integer;
        x : TDyn;                           // Error
    End;

Begin
End.
