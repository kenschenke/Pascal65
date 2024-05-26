Program VarInitTest;

Var
	anyErrors : Boolean;
    ch : Char = 'k';
    bool1 : Boolean;
    bool2 : Boolean = True;
    b1 : Byte;
    b2 : Byte = 201;
    s1 : ShortInt;
    s2 : ShortInt = -123;
    i1 : Integer;
    i2 : Integer = -12345;
	w1 : Word;
    w2 : Word = 12345;
	l1 : LongInt;
    l2 : LongInt = -123456;
	c1 : Cardinal;
    c2 : Cardinal = 12345678;
    str1 : String;
    str2 : String = 'Hello, World';
    r1 : Real;
    r2 : Real = 123.456;

Procedure Error(num : Integer);
Begin
    Writeln('VarInit (', num, ')');
    anyErrors := true;
End;

Begin
	anyErrors := false;

	Writeln('Running');

    If bool1 <> False Then Error(1);
    If bool2 <> True Then Error(2);

    If b1 <> 0 Then Error(3);
    If b2 <> 201 Then Error(4);

    If s1 <> 0 Then Error(5);
    If s2 <> -123 Then Error(6);

    If i1 <> 0 Then Error(7);
    If i2 <> -12345 Then Error(8);

    If w1 <> 0 Then Error(9);
    If w2 <> 12345 Then Error(10);

    If l1 <> 0 Then Error(11);
    If l2 <> -123456 Then Error(12);

    If c1 <> 0 Then Error(13);
    If c2 <> 12345678 Then Error(14);

    If ch <> 'k' Then Error(15);

    If (Length(str1) <> 0) Or (CompareStr(str1, '') <> 0) Then Error(16);
    If (Length(str2) <> 12) Or (CompareStr(str2, 'Hello, World') <> 0)
        Then Error(17);

    If r1 <> 0 Then Error(18);
    If CompareStr(WriteStr(r2:0:2), '123.46') <> 0 Then Error(19);

    If anyErrors Then Begin
        Write('Press any key');
        ch := GetKey;
    End;
End.
