Program CaseInt(input, output);

Var
    i : integer;

Begin
    Case i Of
        1: writeln(i + 1);
        2, 3: Begin
            writeln(i + 3);
            writeln(i div 3);
        End;
        7, 8, 9: writeln(i * 9);
    End;
End.
