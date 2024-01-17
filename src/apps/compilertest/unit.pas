(* Unit Tests *)

Program UnitTest;

Uses Unit1;

Var
    anyErrors : Boolean;
    i : Integer;
    rec : UnitRec;
    ar : UnitArray;

Procedure Error(num : Integer);
Begin
    Writeln('UnitTest (', num, ')');
    anyErrors := true;
End;

Begin
    anyErrors := false;

    Writeln('Running');

    PublicProc(6);
    If Shared <> 18 Then Error(1);

    If PublicFunc1(2, 4) <> 176 Then Error(2);

    If PublicColor(Green) <> 1 Then Error(3);

    rec.i := 3;
    rec.j := 7;
    PublicRec(rec);
    If rec.i <> 6 Then Error(4);
    If rec.j <> 12 Then Error(5);

    For i := 1 To 5 Do ar[i] := i;
    PublicArray(ar);
    For i := 1 To 5 Do If ar[i] <> i * 2 Then Error(6);

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
