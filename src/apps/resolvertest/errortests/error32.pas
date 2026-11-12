// Resolver Error Test 32
// An array of elements of a type that isn't declared. A field of an
// element has no symbol, so it is reported too.

Program Test;

Var
    arr : Array[1..2] Of NoSuchType;    // Error

Begin
    arr[1].x := 1;
End.
