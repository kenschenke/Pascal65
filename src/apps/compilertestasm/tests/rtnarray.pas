Program RtnArray;

Type
    RecType = Record
        a, b : Integer;
        str : String;
    End;
    ArrayType = Array[1..5] Of RecType;

Var
	anyErrors : Boolean;
    ch : Char;
    i : Integer;
    ar1, ar2 : ArrayType;

Procedure Error(num : Integer);
Begin
    Writeln('RtnArray (', num, ')');
    anyErrors := true;
End;

Procedure ProcByValue(arr : ArrayType);
Begin
    For i := 1 To 5 Do Begin
        If arr[i].a <> i*100 Then Error(10);
        If arr[i].b <> i*5 Then Error(11);
        If CompareStr(arr[i].str,
            WriteStr('ar1 str ', i)) <> 0 Then Error(12);
        arr[i].a := i * 10;
        arr[i].b := i * 20;
        arr[i].str := WriteStr('ar1 modified ', i);
    End;
End;

Procedure ProcByRef(Var arr : ArrayType);
Begin
    For i := 1 To 5 Do Begin
        If arr[i].a <> i*50 Then Error(20);
        If arr[i].b <> i*6 Then Error(21);
        If CompareStr(arr[i].str,
            WriteStr('ar2 str ', i)) <> 0 Then Error(22);
        arr[i].a := i * 25;
        arr[i].b := i * 8;
        arr[i].str := WriteStr('ar2 modified ', i);
    End;
End;

Begin
	Writeln('Running array routine tests');
	
    anyErrors := false;

    // Initialize ar1 and ar2
    For i := 1 To 5 Do Begin
        ar1[i].a := i * 100;
        ar1[i].b := i * 5;
        ar1[i].str := WriteStr('ar1 str ', i);

        ar2[i].a := i * 50;
        ar2[i].b := i * 6;
        ar2[i].str := WriteStr('ar2 str ', i);
    End;

    // Test passing by value
    ProcByValue(ar1);
    // Test that array values did not get modified
    For i := 1 To 5 Do Begin
        If ar1[i].a <> i*100 Then Error(13);
        If ar1[i].b <> i*5 Then Error(14);
        If CompareStr(ar1[i].str,
            WriteStr('ar1 str ', i)) <> 0 Then Error(15);
    End;

    // Test passing by reference
    ProcByRef(ar2);
    // Test that array values got modified
    For i := 1 To 5 Do Begin
        If ar2[i].a <> i*25 Then Error(23);
        If ar2[i].b <> i*8 Then Error(24);
        If CompareStr(ar2[i].str,
            WriteStr('ar2 modified ', i)) <> 0 Then Error(25);
    End;

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
