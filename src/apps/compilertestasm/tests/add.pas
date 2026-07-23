Program AddTest;

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
    Writeln('Add (', num, ')');
    anyErrors := true;
End;

Procedure TestByteAdd;
Begin
	b2 := 190;
	b3 := 5;
	b := b2 + b3;
	If b <> 195 Then Error(1);
	If 190 + 5 <> 195 Then Error(2);
	If b2 + 5 <> 195 Then Error(3);
	If 190 + b3 <> 195 Then Error(4);
	If 40190 <> 190 + 40000 Then Error(5);
	If 30190 <> 190 + 30000 Then Error(6);
	If 2147483844 <> 190 + 2147483654 Then Error(7);
	If 123190 <> 190 + 123000 Then Error(8);
	b := 200;
	d := b + 300;
	If d <> 500 Then Error(81);
End;

Procedure TestCardinalAdd;
Begin
	d2 := 2147483748;
	d3 := 1237;
	d := d2 + d3;
	If d <> 2147484985 Then Error(9);
	If 2147484985 <> 2147483748 + 1237 Then Error(10);
	If 2147484985 <> d2 + 1237 Then Error(11);
	If 2147484985 <> 2147483748 + d3 Then Error(12);
	b := 190;
	If 2147483938 <> 2147483748 + b Then Error(13);
	s := 123;
	If 2147483871 <> 2147483748 + s Then Error(14);
	w := 40000;
	If 2147523748 <> 2147483748 + w Then Error(15);
	i := 12345;
	If 2147496093 <> 2147483748 + i Then Error(16);
End;

Procedure TestIntegerAdd;
Begin
	i2 := -1234;
	i3 := 5678;
	i := i2 + i3;
	If i <> 4444 Then Error(17);
	If -1234 + 5678 <> 4444 Then Error(18);
	If i2 + 5678 <> 4444 Then Error(19);
	If -1234 + i3 <> 4444 Then Error(20);
	If 1234 + 190 <> 1424 Then Error(21);
	If 1234 + 27 <> 1261 Then Error(22);
	If 1234 + 40000 <> 41234 Then Error(23);
	If 1234 + 30000 <> 31234 Then Error(24);
	If -1234 + 2147483650 <> 2147482416 Then Error(25);
	If -1234 + 123456 <> 122222 Then Error(26);
	i2 := i3 + 5;
	If i2 <> 5683 Then Error(261);
	b := 200;
	i := b + 300;
	If i <> 500 Then Error(262);
End;

Procedure TestLongIntAdd;
Begin;
	l2 := -123456;
	l3 := 456789;
	l := l2 + l3;
	If l <> 333333 Then Error(27);
	If -123456 + 456789 <> 333333 Then Error(28);
	If l2 + 456789 <> 333333 Then Error(29);
	If -123456 + l3 <> 333333 Then Error(30);
	b := 190;
	If 456979 <> l3 + b Then Error(31);
	s := 123;
	If 456912 <> l3 + s Then Error(32);
	w := 40000;
	If 496789 <> l3 + w Then Error(33);
	i := 12345;
	If 469134 <> l3 + i Then Error(34);
	l2 := l3 + 5;
	If l2 <> 456794 Then Error(341);
	l2 := l3 + 12345;
	If l2 <> 469134 Then Error(342);
End;

Procedure TestShortAdd;
Begin
	s2 := -5;
	s3 := 20;
	s := s2 + s3;
	If s <> 15 Then Error(35);
	If -5 + 20 <> 15 Then Error(36);
	If s2 + 20 <> 15 Then Error(37);
	If 15 <> -5 + s3 Then Error(38);
	If 188 <> -2 + 190 Then Error(39);
	If 39998 <> -2 + 40000 Then Error(40);
	If 1232 <> -2 + 1234 Then Error(41);
	If 2147483632 <> -22 + 2147483654 Then Error(42);
	If 123454 <> -2 + 123456 Then Error(43);
End;

Procedure TestWordAdd;
Begin
	w2 := 43210;
	w3 := 578;
	w := w2 + w3;
	If w <> 43788 Then Error(44);
	If 43210 + 578 <> 43788 Then Error(45);
	If w2 + 578 <> 43788 Then Error(46);
	If 43210 + w3 <> 43788 Then Error(47);
	If 43210 + 190 <> 43400 Then Error(48);
	If 43210 + 20 <> 43230 Then Error(49);
	If 43210 + 2147483650 <> 2147526860 Then Error(50);
	If 43210 + 123456 <> 166666 Then Error(51);
	w2 := w3 + 5;
	If w2 <> 583 Then Error(511);
	i := -5;
	w2 := w3 + i;
	If w2 <> 573 Then Error(512); 
End;

Begin
	anyErrors := false;

	Writeln('Running');

	TestShortAdd;
	TestByteAdd;
	TestIntegerAdd;
	TestWordAdd;
	TestLongIntAdd;
	TestCardinalAdd;

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
