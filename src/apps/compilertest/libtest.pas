Program LibTest;

Uses DemoLib;

Var
	anyErrors : Boolean;
    ch : Char;
    ar : DemoArray;
    i : Integer;
    str : String;
    rec : DemoRecord;

Procedure Error(num : Integer);
Begin
    Writeln('LibTest (', num, ')');
    anyErrors := true;
End;

Begin
	Writeln('Running');
	
    anyErrors := false;

    If DemoArea(5, 6) <> 30 Then Error(1);

    i := 1234;
    DoubleParam(i);
    If i <> 2468 Then Error(2);

    ar[1] := 5;
    ar[2] := 22;
    ar[3] := 1;
    ar[4] := 702;
    ar[5] := -5;
    ar[6] := -23456;
    ar[7] := 12345;
    ar[8] := -1;
    ar[9] := 0;
    ar[10] := 501;
    If Biggest(ar) <> 12345 Then Error(3);

    str := 'Hello, World';
    If LastChar(str) <> 'd' Then Error(4);

    rec.a := 1234;
    rec.b := 2345;
    If SumOfRecord(rec) <> 3579 Then Error(5);

    AppendToString(str, ' Abc123');
    If CompareStr(str, 'Hello, World Abc123') <> 0 Then
        Error(6);

    ar[1] := 12;
    ar[2] := 500;
    ar[3] := 1234;
    ar[4] := 10;
    ar[5] := 10000;
    ar[6] := 1;
    ar[7] := 0;
    ar[8] := 99;
    ar[9] := 321;
    ar[10] := -1000;
    doubleArray(ar);
    If ar[1] <> 24 Then Error(7);
    If ar[2] <> 1000 Then Error(8);
    If ar[3] <> 2468 Then Error(9);
    If ar[4] <> 20 Then Error(10);
    If ar[5] <> 20000 Then Error(11);
    If ar[6] <> 2 Then Error(12);
    If ar[7] <> 0 Then Error(13);
    If ar[8] <> 198 Then Error(14);
    If ar[9] <> 642 Then Error(15);
    If ar[10] <> -2000 Then Error(16);

    rec.a := 500;
    rec.b := -10000;
    doubleRecord(rec);
    If rec.a <> 1000 Then Error(17);
    If rec.b <> -20000 Then Error(18);

    PublicInt := 1234;
    doublePublicInt;
    If PublicInt <> 2468 Then Error(19);

    PublicArray[1] := 12;
    PublicArray[2] := 500;
    PublicArray[3] := 1234;
    PublicArray[4] := 10;
    PublicArray[5] := 10000;
    PublicArray[6] := 1;
    PublicArray[7] := 0;
    PublicArray[8] := 99;
    PublicArray[9] := 321;
    PublicArray[10] := -1000;
    DoublePublicArray;
    If PublicArray[1] <> 24 Then Error(20);
    If PublicArray[2] <> 1000 Then Error(21);
    If PublicArray[3] <> 2468 Then Error(22);
    If PublicArray[4] <> 20 Then Error(23);
    If PublicArray[5] <> 20000 Then Error(24);
    If PublicArray[6] <> 2 Then Error(25);
    If PublicArray[7] <> 0 Then Error(26);
    If PublicArray[8] <> 198 Then Error(27);
    If PublicArray[9] <> 642 Then Error(28);
    If PublicArray[10] <> -2000 Then Error(29);

    PublicRecord.a := 99;
    PublicRecord.b := -2400;
    DoublePublicRecord;
    If PublicRecord.a <> 198 Then Error(30);
    If PublicRecord.b <> -4800 Then Error(31);

    PublicString := 'Hello, World';
    AppendToPublicString(' Abc123');
    If CompareStr(PublicString, 'Hello, World Abc123') <> 0 Then
        Error(32);

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
