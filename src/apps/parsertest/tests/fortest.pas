Program ForTest(input, output);

Var
    i : integer;
    c : char;
Begin
    For i := 0 to 10 Do
        writeln(i);
    For i := 10 downto 1 Do
    Begin
        writeln(i);
        writeln(i + 1);
    End;
    For c := 'a' to 'z' Do
        writeln(c);
End.
