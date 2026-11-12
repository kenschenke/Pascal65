// Resolver Error Test 31
// A field reached through a pointer to a type that isn't declared. The
// field has no symbol.

Program Test;

Var
    p : ^NoSuchType;

Begin
    p^.x := 1;                  // Error
End.
