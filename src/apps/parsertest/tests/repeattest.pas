Program RepeatTest(input, output);

Var
    i : integer;

Begin
    i := 0;
    Repeat
        writeln(i);
        i := i + 5;
    Until i > 5;
End.
