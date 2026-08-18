Program RtnRecord;

Type
    RecType = Record
        a, b : Integer;
        str : String;
        arr : Array[1..5] Of Integer;
    End;

Var
	anyErrors : Boolean;
    ch : Char;
    i : Integer;
    rec1, rec2 : RecType;

Procedure Error(num : Integer);
Begin
    Writeln('RtnRecord (', num, ')');
    anyErrors := true;
End;

Procedure ProcByValue(rec : RecType);
Begin
    If rec.a <> 11111 Then Error(10);
    If rec.b <> 22222 Then Error(11);
    If CompareStr(rec.str, 'Rec 1 String') <> 0 Then Error(12);
    For i := 1 To 5 Do Begin
        If rec.arr[i] <> i*100 Then Error(13);
        rec.arr[i] := i * 7;
    End;

    rec.a := 12121;
    rec.b := 21212;
    rec.str := 'Rec 1 Modified';
End;

Procedure ProcByRef(Var rec : RecType);
Begin
    If rec.a <> 12345 Then Error(20);
    If rec.b <> 23456 Then Error(21);
    If CompareStr(rec.str, 'Rec 2 String') <> 0 Then Error(22);
    For i := 1 To 5 Do Begin
        If rec.arr[i] <> i*5 Then Error(23);
        rec.arr[i] := i * 7;
    End;

    rec.a := 12121;
    rec.b := 21212;
    rec.str := 'Rec 2 Modified';
End;

Begin
	Writeln('Running record routine tests');
	
    anyErrors := false;

    // Initialize rec1 and rec2
    rec1.a := 11111;
    rec1.b := 22222;
    rec1.str := 'Rec 1 String';
    rec2.a := 12345;
    rec2.b := 23456;
    rec2.str := 'Rec 2 String';
    For i := 1 To 5 Do Begin
        rec1.arr[i] := i * 100;
        rec2.arr[i] := i * 5;
    End;

    // Test passing by value
    ProcByValue(rec1);
    // Test that array values did not get modified
    If rec1.a <> 11111 Then Error(14);
    If rec1.b <> 22222 Then Error(15);
    If CompareStr(rec1.str, 'Rec 1 String') <> 0 Then Error(16);
    For i := 1 To 5 Do
        If rec1.arr[i] <> i*100 Then Error(17);

    // Test passing by reference
    ProcByRef(rec2);
    // Test that array values got modified
    If rec2.a <> 12121 Then Error(24);
    If rec2.b <> 21212 Then Error(25);
    If CompareStr(rec2.str, 'Rec 2 Modified') <> 0 Then Error(26);
    For i := 1 To 5 Do
        If rec2.arr[i] <> i*7 Then Error(27);

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
