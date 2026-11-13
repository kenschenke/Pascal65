// Resolver Error Test 46
// Undefined names in the width of the first of 150 Writeln
// arguments and in the last. The arguments are chained through
// expr::right, like array literal elements. Both errors are
// reported on the line that ends the statement.

Program Test;

Var
    i : Integer;

Begin
    Writeln(i:BadWidth, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i,
        i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i,
        i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i,
        i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i,
        i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i,
        i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i,
        i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i,
        i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i,
        i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i,
        i, i, i, i, i, BadArg); // Error
End.
