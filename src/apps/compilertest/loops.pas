(* Loop Tests *)

Program Loops;
Var
    anyErrors : Boolean;
    i, j : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('Loop (', num, ')');
    anyErrors := true;
End;

Begin
    anyErrors := false;

    Writeln('Running');

    j := 10;
    For i := 1 To 10 Do j := j - 1;
    If j <> 0 Then Error(1);

    j := 0;
    For i := 10 DownTo 1 Do j := j + 1;
    If j <> 10 Then Error(2);

    j := 1;
    Repeat
        j := j + 1;
    Until j = 10;
    If j <> 10 Then Error(3);

    i := 1;
    While i <> 10 Do
        i := i + 1;
    If i <> 10 Then Error(4);

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
