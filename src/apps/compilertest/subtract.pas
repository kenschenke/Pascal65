Program SubtractTest;

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
    Writeln('Subtract (', num, ')');
    anyErrors := true;
End;

Procedure TestByteSubtract;
Begin
	b2 := 190;
	b3 := 5;
	b := b2 - b3;
	If b <> 185 Then Error(1);
	If 190 - 5 <> 185 Then Error(2);
	If b2 - 5 <> 185 Then Error(3);
	If 190 - b3 <> 185 Then Error(4);
	If 40000 <> 40190 - 190 Then Error(5);
	If 30000 <> 30190 - 190 Then Error(6);
	If 2147483290 - 190 <> 2147483100 Then Error(7);
	If 123100 <> 123290 - 190 Then Error(8);
End;

Procedure TestCardinalSubtract;
Begin
	d2 := 2147483748;
	d3 := 1237;
	d := d2 - d3;
	If d <> 2147482511 Then Error(9);
	If 2147482511 <> 2147483748 - 1237 Then Error(10);
	If 2147482511 <> d2 - 1237 Then Error(11);
	If 2147482511 <> 2147483748 - d3 Then Error(12);
	b := 190;
	If 2147482100 <> 2147482290 - 190 Then Error(13);
	s := 100;
	If 2147482511 <> 2147482611 - s Then Error(14);
	i := 2511;
	If 2147480000 <> 2147482511 - i Then Error(15);
	w := 42511;
	If 2147400000 <> 2147442511 - w Then Error(16);
End;

Procedure TestIntegerSubtract;
Begin
	i2 := 1234;
	i3 := 234;
	i := i2 - i3;
	If i <> 1000 Then Error(17);
	If 1000 <> 1234 - 234 Then Error(18);
	If 1000 <> i2 - 234 Then Error(19);
	If 1000 <> 1234 - i3 Then Error(20);
	If 1200 <> 1234 - 34 Then Error(21);
	If 1000 <> 2234 - 1234 Then Error(22);
	If 2147480000 <> 2147483650 - 3650 Then Error(24);
End;

Procedure TestLongIntSubtract;
Begin
	l2 := 223456;
	l3 := 100000;
	l := l2 - l3;
	If l <> 123456 Then Error(25);
	If 223456 - 100000 <> 123456 Then Error(26);
	If l2 - 100000 <> 123456 Then Error(27);
	If 223456 - l3 <> 123456 Then Error(28);
	b := 156;
	If l2 - b <> 223300 Then Error(29);
	s := 56;
	If l2 - s <> 223400 Then Error(30);
	i := 456;
	If l2 - i <> 223000 Then Error(31);
	w := 40000;
	If l2 - w <> 183456 Then Error(32);
End;

Procedure TestShortSubtract;
Begin
	 s2 := 100;
	 s3 := 20;
	 s := s2 - s3;
	 If s <> 80 Then Error(33);
	 If 100 - 20 <> 80 Then Error(34);
	 If s2 - 20 <> 80 Then Error(35);
	 If 100 - 20 <> 80 Then Error(36);
	 If 31800 <> 32000 - 200 Then Error(37);
	 If 40000 <> 42000 - 2000 Then Error(38);
	 If 123126 <> 123226 - 100 Then Error(39);
	 If 2147483600 <> 2147483632 - 32 Then Error(40);
End;

Procedure TestWordSubtract;
Begin
	w2 := 42000;
	w3 := 1000;
	w := w2 - w3;
	If w <> 41000 Then Error(41);
	If 42000 - 1000 <> 41000 Then Error(42);
	If w2 - 1000 <> 41000 Then Error(43);
	If 42000 - w3 <> 41000 Then Error(44);
	If 41190 - 190 <> 41000 Then Error(45);
	If 41190 - 90 <> 41100 Then Error(46);
	If 42000 - 2000 <> 40000 Then Error(47);
	If 42000 - 40000 <> 2000 Then Error(48);
	If 140000 - 40000 <> 100000 Then Error(49);
End;

Begin
	anyErrors := false;

	Writeln('Running');

	TestByteSubtract;
	TestCardinalSubtract;
	TestIntegerSubtract;
	TestLongIntSubtract;
	TestShortSubtract;
	TestWordSubtract;

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
