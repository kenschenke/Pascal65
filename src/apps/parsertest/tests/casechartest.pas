Program CaseChar(input, output);

Var
    c : char;

Begin
    Case c Of
        'a': writeln('a', c);
        'b', 'c': Begin
            writeln(c, 'd');
            writeln('e', c);
        End;
        'f', 'g', 'h':
            writeln(c, 'z', 'x');
    End;
End.
