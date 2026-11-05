// Resolver Error Test 3
// A named array type as the element of a dynamic array

Program Test;

Type
    TStatic = Array[1..3] Of Integer;

Var
    i : Integer;
    a : Array Of TStatic;                   // Error

Begin
End.
