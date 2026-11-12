// Resolver Error Test 33
// A subrange with no high limit. The parser reports it, and the
// resolver goes on.

Program Test;

Var
    x : 1..;                    // Error

Begin
End.
