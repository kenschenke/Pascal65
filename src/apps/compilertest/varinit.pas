Program VarInitTest;

Type
    Rows = Array[1..3] Of Array[1..3] Of Integer;

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
    nums : Array[1..5] Of Integer = (5, 67, 54, -1, 99);
    rw : Rows = (
        (9, 8, 7), (6, 5, 4), (3, 2, 1)
    );
    r : Array[1..5] Of Real = (3.14, 5.3455, -123.456, 16.453);

Procedure Error(num : Integer);
Begin
    Writeln('VarInit (', num, ')');
    anyErrors := true;
End;

Procedure ProcInit;
Var
    i : Integer = 1234;
    j : Integer = 10;
    r : Real = 123.456;
    ar : Array[1..5] Of Integer = (10, 20, 30, 40, 50);
Begin
    If i <> 1234 Then Error(38);
    If Abs(r-123.456) > 0.01 Then Error(39);
    
    For i := 1 To 5 Do Begin
        If ar[i] <> j Then Error(40);
        j := j + 10;
    End;
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

    If nums[1] <> 5 Then Error(20);
    If nums[2] <> 67 Then Error(21);
    If nums[3] <> 54 Then Error(22);
    If nums[4] <> -1 Then Error(23);
    If nums[5] <> 99 Then Error(24);

    If rw[1][1] <> 9 Then Error(25);
    If rw[1][2] <> 8 Then Error(26);
    If rw[1][3] <> 7 Then Error(27);
    If rw[2][1] <> 6 Then Error(28);
    If rw[2][2] <> 5 Then Error(29);
    If rw[2][3] <> 4 Then Error(30);
    If rw[3][1] <> 3 Then Error(31);
    If rw[3][2] <> 2 Then Error(32);
    If rw[3][3] <> 1 Then Error(33);

    If Abs(r[1]-3.14) > 0.01 Then Error(34);
    If Abs(r[2]-5.3455) > 0.01 Then Error(35);
    If Abs(r[3]+123.456) > 0.01 Then Error(36);
    If Abs(r[4]-16.453) > 0.01 Then Error(37);

    ProcInit;

    If anyErrors Then Begin
        Write('Press any key');
        ch := GetKey;
    End;
End.
