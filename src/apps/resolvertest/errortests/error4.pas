// Resolver Error Test 4
// A named dynamic array type as the element of a nested array

Program Test;

Type
    TDyn = Array Of Integer;

Var
    i : Integer;
    a : Array[1..2] Of Array[1..3] Of TDyn; // Error

Begin
End.
