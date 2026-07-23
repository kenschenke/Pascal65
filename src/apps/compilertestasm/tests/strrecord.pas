Program StrRecord;

Type
    MyRecord = Record
        a, b : Integer;
        str1, str2 : String;
    End;

Var
    anyErrors : Boolean;
	ch : Char;
    GlobalRec : MyRecord;

Procedure Error(num : Integer);
Begin
    Writeln('StrArray (', num, ')');
    anyErrors := true;
End;

Procedure TestPassByValue(LocalRec : MyRecord);
Begin
    If LocalRec.a <> 12345 Then Error(20);
    If LocalRec.b <> 23456 Then Error(21);
    If CompareStr(LocalRec.str1, 'GlobalStr1') <> 0 Then Error(22);
    If CompareStr(LocalRec.str2, 'GlobalStr2') <> 0 Then Error(23);

    LocalRec.str1 := 'LocalStr1';
    LocalRec.str2 := 'LocalStr2';

    If CompareStr(LocalRec.str1, 'LocalStr1') <> 0 Then Error(24);
    If CompareStr(LocalRec.str2, 'LocalStr2') <> 0 Then Error(25);
End;

Procedure TestPassByReference(Var LocalRec : MyRecord);
Begin
    If LocalRec.a <> 12345 Then Error(30);
    If LocalRec.b <> 23456 Then Error(31);
    If CompareStr(LocalRec.str1, 'GlobalStr1') <> 0 Then Error(32);
    If CompareStr(LocalRec.str2, 'GlobalStr2') <> 0 Then Error(33);

    LocalRec.a := 23232;
    LocalRec.b := 12121;
    LocalRec.str1 := 'LocalStr1';
    LocalRec.str2 := 'LocalStr2';

    If CompareStr(LocalRec.str1, 'LocalStr1') <> 0 Then Error(34);
    If CompareStr(LocalRec.str2, 'LocalStr2') <> 0 Then Error(35);
End;

Begin
    anyErrors := false;

	Writeln('Running');

    If CompareStr(GlobalRec.str1, '') <> 0 Then Error(10);
    If CompareStr(GlobalRec.str2, '') <> 0 Then Error(11);
    If Length(GlobalRec.str1) <> 0 Then Error(12);
    If Length(GlobalRec.str2) <> 0 Then Error(13);

    GlobalRec.a := 12345;
    GlobalRec.b := 23456;
    GlobalRec.str1 := 'GlobalStr1';
    GlobalRec.str2 := 'GlobalStr2';

    TestPassByValue(GlobalRec);
    If CompareStr(GlobalRec.str1, 'GlobalStr1') <> 0 Then Error(14);
    If CompareStr(GlobalRec.str2, 'GlobalStr2') <> 0 Then Error(15);

    TestPassByReference(GlobalRec);
    If CompareStr(GlobalRec.str1, 'LocalStr1') <> 0 Then Error(16);
    If CompareStr(GlobalRec.str2, 'LocalStr2') <> 0 Then Error(17);
    If GlobalRec.a <> 23232 Then Error(18);
    If GlobalRec.b <> 12121 Then Error(19);

    If anyErrors Then Begin
        Write('Press a key to continue:');
		ch := GetKey;
    End;
End.
