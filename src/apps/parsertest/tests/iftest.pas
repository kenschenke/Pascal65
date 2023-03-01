Program IfTest(input, output);

Var
    i : integer;

Begin
    If i + 1 > 5 Then
        writeln(i);
    If (i + 1 > 5) And (i * 2 < 200) Then Begin
        writeln(i);
        writeln(i Div 10);
    End;
    If ((i * 2 < 100) And (i < 5)) Or (i > 1000) Then
        writeln(i)
    Else
        writeln(i * 10);
    If i > 0 Then
        writeln(i)
    Else Begin
        writeln(i * 2);
        writeln(i > 0);
    End;
End.
