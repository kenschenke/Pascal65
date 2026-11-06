// Resolver Error Test 6
// A named dynamic array type as a field of an anonymous record that is
// the element of an array variable

Program Test;

Type
    TDyn = Array Of Integer;

Var
    a : Array[1..3] Of Record
        x : TDyn;                           // Error
    End;

Begin
End.
