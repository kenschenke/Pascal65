Program MultiplyTest;

Var
	anyErrors : Boolean;
	b, b2, b3 : Byte;
	s, s2, s3 : ShortInt;
	i, i2, i3 : Integer;
	w, w2, w3 : Word;
	r : Real;
	l, l2, l3 : LongInt;
	d, d2, d3 : Cardinal;

Procedure Error(num : Integer);
Begin
    Writeln('Multiply (', num, ')');
    anyErrors := true;
End;

Procedure TestByteMultiply;
Begin
	b2 := 12;
	b3 := 5;
	w := b2 * b3;
	If w <> 60 Then Error(1);
	If 12 * 5 <> 60 Then Error(2);
	If b2 * 5 <> 60 Then Error(3);
	If 12 * b3 <> 60 Then Error(4);
	If -200000 <> 40000 * -5 Then Error(5);
	l := -30000;
	l := l * 5;
	If l <> -150000 Then Error(6);
	If 2147483290 * -1 <> -2147483290 Then Error(7);
	If -120000 <> -60000 * 2 Then Error(8);
    If 0 <> 5 * 0 Then Error(9);
    If 0 <> 0 * 123 Then Error(10);
End;

Procedure TestCardinalMultiply;
Begin
	d2 := 123456;
	d3 := 2;
	d := d2 * d3;
	If d <> 246912 Then Error(11);
    If 2147483748 * 0 <> 0 Then Error(12);
    If 0 * 2147483748 <> 0 Then Error(13);
End;

Procedure TestIntegerMultiply;
Begin
	i2 := 123;
	i3 := 45;
	l := i2 * i3;
	If l <> 5535 Then Error(17);
    If -2468 <> 1234 * -2 Then Error(18);
    If -2468 <> -1234 * 2 Then Error(19);
    If 2468 <> -1234 * -2 Then Error(20);
    If 0 <> 12345 * 0 Then Error(21);
    If 0 <> 0 * 12345 Then Error(22);
End;

Begin
	anyErrors := false;

	Writeln('Running');

	TestByteMultiply;
	TestCardinalMultiply;
	TestIntegerMultiply;

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
