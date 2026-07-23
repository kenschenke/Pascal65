Program StrArray;

Type
    MyArray = Array[1..5] Of String;

Var
    anyErrors : Boolean;
	ch : Char;
    i : Integer;
    GlobalArr : MyArray = ('One', 'Two', 'Three', 'Four', 'Five');
    EmptyArr : MyArray;
    PartialArr : MyArray = ('First', 'Second', 'Third');

Procedure Error(num : Integer);
Begin
    Writeln('StrArray (', num, ')');
    anyErrors := true;
End;

Procedure TestPassByReference(Var LocalArr : MyArray);
Begin
    If CompareStr(LocalArr[1], 'One') <> 0 Then Error(30);
    If CompareStr(LocalArr[2], 'Two') <> 0 Then Error(31);
    If CompareStr(LocalArr[3], 'Three') <> 0 Then Error(32);
    If CompareStr(LocalArr[4], 'Four') <> 0 Then Error(33);
    If CompareStr(LocalArr[5], 'Five') <> 0 Then Error(34);

    For i := 1 To 5 Do LocalArr[i] := WriteStr('Modified ', i);
End;

Procedure TestPassByValue(LocalArr : MyArray);
Var i : Integer;
Begin
    If CompareStr(LocalArr[1], 'One') <> 0 Then Error(20);
    If CompareStr(LocalArr[2], 'Two') <> 0 Then Error(21);
    If CompareStr(LocalArr[3], 'Three') <> 0 Then Error(22);
    If CompareStr(LocalArr[4], 'Four') <> 0 Then Error(23);
    If CompareStr(LocalArr[5], 'Five') <> 0 Then Error(24);

    For i := 1 To 5 Do LocalArr[i] := WriteStr('Modified ', i);
End;

Begin
    anyErrors := false;

	Writeln('Running');

    If CompareStr(GlobalArr[1], 'One') <> 0 Then Error(10);
    If CompareStr(GlobalArr[2], 'Two') <> 0 Then Error(11);
    If CompareStr(GlobalArr[3], 'Three') <> 0 Then Error(12);
    If CompareStr(GlobalArr[4], 'Four') <> 0 Then Error(13);
    If CompareStr(GlobalArr[5], 'Five') <> 0 Then Error(14);

    TestPassByValue(GlobalArr);
    If CompareStr(GlobalArr[1], 'One') <> 0 Then Error(15);
    If CompareStr(GlobalArr[2], 'Two') <> 0 Then Error(16);
    If CompareStr(GlobalArr[3], 'Three') <> 0 Then Error(17);
    If CompareStr(GlobalArr[4], 'Four') <> 0 Then Error(18);
    If CompareStr(GlobalArr[5], 'Five') <> 0 Then Error(19);

    TestPassByReference(GlobalArr);
    If CompareStr(GlobalArr[1], 'Modified 1') <> 0 Then Error(40);
    If CompareStr(GlobalArr[2], 'Modified 2') <> 0 Then Error(41);
    If CompareStr(GlobalArr[3], 'Modified 3') <> 0 Then Error(42);
    If CompareStr(GlobalArr[4], 'Modified 4') <> 0 Then Error(43);
    If CompareStr(GlobalArr[5], 'Modified 5') <> 0 Then Error(44);

    For i := 1 To 5 Do Begin
        If CompareStr(EmptyArr[i], '') <> 0 Then Error(50);
        If Length(EmptyArr[i]) <> 0 Then Error(51);
    End;
    EmptyArr[1] := 'Six';
    EmptyArr[2] := 'Seven';
    EmptyArr[3] := 'Eight';
    EmptyArr[4] := 'Nine';
    EmptyArr[5] := 'Ten';
    If CompareStr(EmptyArr[1], 'Six') <> 0 Then Error(52);
    If CompareStr(EmptyArr[2], 'Seven') <> 0 Then Error(53);
    If CompareStr(EmptyArr[3], 'Eight') <> 0 Then Error(54);
    If CompareStr(EmptyArr[4], 'Nine') <> 0 Then Error(55);
    If CompareStr(EmptyArr[5], 'Ten') <> 0 Then Error(56);

    If CompareStr(PartialArr[1], 'First') <> 0 Then Error(60);
    If CompareStr(PartialArr[2], 'Second') <> 0 Then Error(61);
    If CompareStr(PartialArr[3], 'Third') <> 0 Then Error(62);
    If CompareStr(PartialArr[4], '') <> 0 Then Error(63);
    If CompareStr(PartialArr[5], '') <> 0 Then Error(64);
    If Length(PartialArr[4]) <> 0 Then Error(65);
    If Length(PartialArr[5]) <> 0 Then Error(66);

    If anyErrors Then Begin
        Write('Press a key to continue:');
		ch := GetKey;
    End;
End.
