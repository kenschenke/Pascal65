// Resolver Error Test 41
// An array index of a type that renames an enumeration

Program Test;

Type
    Color = (Red, Green, Blue);
    Shade = Color;

Var
    a : Array[Shade] Of Byte;   // Error

Begin
End.
