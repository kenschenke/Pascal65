Program UnitUses;

// A unit used by the program and by another unit is one unit. UUseB uses
// UUseA, and so does the program. The parser once added UUseA to the
// units list twice (addUnit's name comparison never matched), so it had
// two frames and its init block ran twice, which pushed its slots again
// and moved UUseB's. This checks every initial value, that UUseA's
// variables are the same ones from the program and from UUseB, and that
// writing one variable leaves the others alone.

Uses UUseA, UUseB;

Var
    anyErrors : Boolean;
    errList : String;
    before : Integer = 1234;

Procedure Error(num : Integer);
Begin
    Writeln('UnitUses (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'unituses:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Procedure TestInitialValues;
Begin
    If before <> 1234 Then Error(1);
    If aCount <> 7 Then Error(2);
    If CompareStr(aName, 'alpha') <> 0 Then Error(3);
    If ATotal <> 107 Then Error(4);
    If CompareStr(bWord, 'beta') <> 0 Then Error(5);
    If bCount <> -3 Then Error(6);
    If BSeesA <> 7 Then Error(7);
End;

Procedure TestShared;
Begin
    // The program writes UUseA's variable; UUseB sees it
    aCount := 20;
    If BSeesA <> 20 Then Error(8);

    // UUseB writes UUseA's variables; the program sees them
    BBumpBoth(5);
    If aCount <> 25 Then Error(9);
    If CompareStr(aName, 'alpha+') <> 0 Then Error(10);
    If ATotal <> 126 Then Error(11);
    If bCount <> 2 Then Error(12);

    // The program calls UUseA directly
    ABump(1);
    If aCount <> 26 Then Error(13);
    If ATotal <> 128 Then Error(14);

    // Nothing else moved
    If before <> 1234 Then Error(15);
    If CompareStr(bWord, 'beta') <> 0 Then Error(16);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running unit uses tests');

    TestInitialValues;
    TestShared;

    If anyErrors Then ReportFailure;
End.
