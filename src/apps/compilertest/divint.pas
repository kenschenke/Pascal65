Program DivIntTest;

Var
	anyErrors : Boolean;
	ch : Char;
	b, b2, b3 : Byte;
	s, s2, s3 : ShortInt;
	i, i2, i3 : Integer;
	w, w2, w3 : Word;
	r : Real;
	l, l2, l3 : LongInt;
	d, d2, d3 : Cardinal;

Procedure Error(num : Integer);
Begin
    Writeln('DivInt (', num, ')');
    anyErrors := true;
End;

Procedure TestByteDivide;
Begin
	b2 := 12;
	b3 := 5;
	w := b2 Div b3;
	If w <> 2 Then Error(1);
	If 12 Div 5 <> 2 Then Error(2);
	If b2 Div 5 <> 2 Then Error(3);
	If 12 Div b3 <> 2 Then Error(4);
	If -5 <> 60 Div -12 Then Error(5);
	If -30000 Div 10 <> -3000 Then Error(6);
	l := 60000;
	If -60000 <> l Div -1 Then Error(7);
	If -60000 <> -120000 Div 2 Then Error(8);
    If 0 <> 0 Div 123 Then Error(9);
	b2 := 128;
	If b2 Div 2 <> 64 Then Error(10);
End;

Procedure TestWordDivide;
Begin
	w2 := 12345;
	w3 := 234;
	If w2 Div w3 <> 52 Then Error(11);
	w2 := 32768;
	w3 := 2;
	If w2 Div w3 <> 16384 Then Error(12);
	w2 := 54321;
	w3 := 2345;
	If w2 Div w3 <> 23 Then Error(13);
End;

Procedure TestCardinalDivide;
Begin
	d2 := 123456;
	d3 := 2;
	d := d2 Div d3;
	If d <> 61728 Then Error(10);
	If -176 <> 12345678 Div -70000 Then Error(14);
    If 0 Div 2147483748 <> 0 Then Error(15);
End;

Procedure TestIntegerDivide;
Begin
	i2 := 135;
	i3 := 45;
	l := i2 Div i3;
	If l <> 3 Then Error(16);
    If -617 <> 1234 Div -2 Then Error(17);
    If -617 <> -1234 Div 2 Then Error(18);
    If 617 <> -1234 Div -2 Then Error(19);
    If 0 <> 0 Div 12345 Then Error(20);
End;

Begin
	anyErrors := false;

	Writeln('Running');

	TestByteDivide;
	TestCardinalDivide;
	TestIntegerDivide;
	TestWordDivide;

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
