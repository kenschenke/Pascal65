// Resolver Error Test 14
// Subrange limits of a character and an enumeration value

Program Test;

Type
    Color = (Red, Green);

Var
    x : 'a'..Green;             // Error

Begin
End.
