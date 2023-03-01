Program WhileTest(input, output);

Var
    i : integer;

Begin
    i := 0;
    While i < 5 Do
        i := i + 1;
    i := 5;
    While i >= 0 Do Begin
        writeln(i);
        i := i - 1;
    End;
End.
