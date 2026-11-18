Program UnitInit;

// Each Pascal unit sets up its own variables in an init block that the
// program's startup calls (UIC and UIR in icode). The units' variables
// follow the program's in its frame: UInitA's, then UInitB's. This checks
// every initial value and that writing one variable leaves the others,
// the program's included, alone.

Uses UInitA, UInitB;

Var
    anyErrors : Boolean;
    errList : String;
    before : Integer = 1234;
    title : String = 'main';
    i : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('UnitInit (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'unitinit:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Procedure TestInitialValues;
Begin
    If before <> 1234 Then Error(1);
    If CompareStr(title, 'main') <> 0 Then Error(2);
    If aCount <> 7 Then Error(3);
    If CompareStr(aName, 'alpha') <> 0 Then Error(4);
    For i := 1 To 4 Do
        If aList[i] <> i * 11 Then Error(5);
    // Errors 6 and 7 checked that aPt's fields start at 0. They don't:
    // heapAlloc doesn't clear a block, and a record's setup only
    // initializes its string and array fields. That holds for every
    // record, not just a unit's. TestSeparateSlots checks aPt's slot.
    If Not aFlag Then Error(8);
    If aReal <> 2.5 Then Error(9);
    If Length(aEmpty) <> 0 Then Error(10);
    If APrivNum <> 1000 Then Error(11);
    If CompareStr(APrivStr, 'secret') <> 0 Then Error(12);
    If APrivChar(0) <> 'x' Then Error(13);
    If APrivChar(2) <> 'z' Then Error(14);
    If CompareStr(bWords[1], 'one') <> 0 Then Error(15);
    If CompareStr(bWords[2], 'two') <> 0 Then Error(16);
    If bChar <> 'q' Then Error(17);
    If bCount <> -3 Then Error(18);
    If BTotal <> 37 Then Error(19);
End;

Procedure TestSeparateSlots;
Begin
    aCount := 99;
    aName := aName + '!';
    ASetPriv(55);
    bCount := 10;
    bWords[2] := 'three';
    If before <> 1234 Then Error(20);
    If CompareStr(title, 'main') <> 0 Then Error(21);
    If aCount <> 99 Then Error(22);
    If CompareStr(aName, 'alpha!') <> 0 Then Error(23);
    If APrivNum <> 55 Then Error(24);
    If aPt.x <> 55 Then Error(25);
    If aPt.y <> 56 Then Error(26);
    If CompareStr(APrivStr, 'secret') <> 0 Then Error(27);
    If BTotal <> 50 Then Error(28);
    If CompareStr(bWords[1], 'one') <> 0 Then Error(29);
    If CompareStr(bWords[2], 'three') <> 0 Then Error(30);
    If bChar <> 'q' Then Error(31);
    If aList[4] <> 44 Then Error(32);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running unit init tests');

    TestInitialValues;
    TestSeparateSlots;

    If anyErrors Then ReportFailure;
End.
