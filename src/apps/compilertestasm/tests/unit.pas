(* Unit Tests *)

Program UnitTest;

Uses Unit1;

Var
    anyErrors : Boolean;
    errList : String;
    i : Integer;
    rec : UnitRec;
    ar : UnitArray;

Procedure Error(num : Integer);
Begin
    Writeln('UnitTest (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure ReportFailure;
Var
    f : Text;
    acc : String;
Begin
    // Keep entries from earlier tests
    acc := '';
    Assign(f, 'testfailed');
    Reset(f);
    If IOResult = 0 Then Readln(f, acc);
    Close(f);
    If Length(acc) < 150 Then acc := acc + 'unit:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running tests for units');

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

    If TestSystemOdd(123) <> True Then Error(7);

    If anyErrors Then ReportFailure;
End.
