Program LibTest2;

// Tests a library in the v2 format (a relocation table). DemoLib2 has
// DemoLib's routines, a table of bytes in its own page range, a BSS and an
// init routine. LibTest tests the v1 format with DemoLib.

Uses DemoLib2;

Var
    anyErrors : Boolean;
    errList : String;
    ar : DemoArray;
    i : Integer;
    str : String;
    rec : DemoRecord;

Procedure Error(num : Integer);
Begin
    Writeln('LibTest2 (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure MyCallbackProc(num : Integer);
Begin
    If i <> 32121 Then Error(16);
    i := num;
End;

Function MyCallbackFunc : Integer;
Begin
    MyCallbackFunc := 12121;
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
    If Length(acc) < 150 Then acc := acc + 'libtest2:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    Writeln('Running v2 library tests');

    anyErrors := false;
    errList := '';

    // The bytes in the library's page range weren't relocated
    If PageBytes <> 250 Then Error(1);

    // The init routine ran and the BSS is zero, then keeps its value
    If BssCounter <> 1 Then Error(2);
    If BssCounter <> 2 Then Error(3);

    If DemoArea(5, 6) <> 30 Then Error(4);

    i := 1234;
    DoubleParam(i);
    If i <> 2468 Then Error(5);

    For i := 1 To 10 Do ar[i] := i * 10;
    ar[7] := 12345;
    If Biggest(ar) <> 12345 Then Error(6);

    str := 'Hello, World';
    If LastChar(str) <> 'd' Then Error(7);

    rec.a := 1234;
    rec.b := 2345;
    If SumOfRecord(rec) <> 3579 Then Error(8);

    AppendToString(str, ' Abc123');
    If CompareStr(str, 'Hello, World Abc123') <> 0 Then Error(9);

    rec.a := 500;
    rec.b := -10000;
    DoubleRecord(rec);
    If (rec.a <> 1000) Or (rec.b <> -20000) Then Error(10);

    PublicInt := 1234;
    DoublePublicInt;
    If PublicInt <> 2468 Then Error(11);

    For i := 1 To 10 Do PublicArray[i] := i;
    DoublePublicArray;
    If (PublicArray[1] <> 2) Or (PublicArray[10] <> 20) Then Error(12);

    PublicRecord.a := 99;
    PublicRecord.b := -2400;
    DoublePublicRecord;
    If (PublicRecord.a <> 198) Or (PublicRecord.b <> -4800) Then Error(13);

    PublicString := 'Hello, World';
    AppendToPublicString(' Abc123');
    If CompareStr(PublicString, 'Hello, World Abc123') <> 0 Then
        Error(14);

    i := 32121;
    RegisterDemoProc(@MyCallbackProc);
    TestDemoProc(12345);
    If i <> 12345 Then Error(15);

    RegisterDemoFunc(@MyCallbackFunc);
    If TestDemoFunc <> 12121 Then Error(17);

    If BssCounter <> 3 Then Error(18);

    If anyErrors Then ReportFailure;
End.
