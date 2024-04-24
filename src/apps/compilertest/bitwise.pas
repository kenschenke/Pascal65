Program BitwiseTest;

Var
	anyErrors : Boolean;
	ch : Char;
	i : Integer;
	b, b2, b3 : Byte;
	w, w2, w3 : Word;
	d, d2, d3 : Cardinal;

Procedure Error(num : Integer);
Begin
    Writeln('Bitwise (', num, ')');
    anyErrors := true;
End;

Procedure TestBitwiseByte;
Begin
    b2 := 51;
    b3 := 24;
    b := b2 ! 24; If b <> 59 Then Error(1);
    b := 24 ! b2; If b <> 59 Then Error(2);
    b := b3 ! 51; If b <> 59 Then Error(3);
    b := 51 ! b3; If b <> 59 Then Error(4);
    b := b2 & 24; If b <> 16 Then Error(5);
    b := 24 & b2; If b <> 16 Then Error(6);
    b := b3 & 51; If b <> 16 Then Error(7);
    b := 51 & b3; If b <> 16 Then Error(8);

	b := 1;
	b2 := b << 0;
	If b2 <> 1 Then Error(9);
	b3 := 1;
	For i := 1 To 7 Do Begin
		b2 := b << i;
		b3 := b3 * 2;
		If b2 <> b3 Then Error(10);
	End;
	b2 := b << 8; If b2 <> 1 Then Error(11);
	b2 := b << 9; If b2 <> 1 Then Error(12);

	b := 85;
	b2 := b >> 0;
	If b2 <> 85 Then Error(13);
	b3 := 85;
	For i := 1 To 7 Do Begin
		b2 := b >> i;
		b3 := b3 Div 2;
		If b2 <> b3 Then Begin
			Error(14);
		End;
	End;
	b2 := b >> 8; If b2 <> 85 Then Error(15);
	b2 := b >> 9; If b2 <> 85 Then Error(16);

	b := 85;
	b2 := b << 0;
	If b2 <> 85 Then Error(17);
	b3 := 85;
	For i := 1 To 7 Do Begin
		b2 := b << i;
		b3 := b3 * 2;
		If b2 <> b3 Then Begin
			Error(18);
		End;
	End;
	b2 := b >> 8; If b2 <> 85 Then Error(19);
	b2 := b >> 9; If b2 <> 85 Then Error(20);

	b := 85;
	b2 := @b;
	If b2 <> 170 Then Error(21);
End;

Procedure TestBitwiseWord;
Begin
    w2 := $d5aa;
    w3 := $1357;
    w := w2 ! $1357; If w <> $d7ff Then Error(22);
    w := $1357 ! w2; If w <> $d7ff Then Error(23);
    w := $1357 ! $d5aa; If w <> $d7ff Then Error(24);
    w := $d5aa ! $1357; If w <> $d7ff Then Error(25);
    w := w2 & $1357; If w <> $1102 Then Error(26);
    w := $1357 & w2; If w <> $1102 Then Error(27);
    w := w3 & $d5aa; If w <> $1102 Then Error(28);
    w := $d5aa & w3; If w <> $1102 Then Error(29);

	w := 1;
	w2 := w << 0;
	If w2 <> 1 Then Error(30);
	w3 := 1;
	b := 2;
	For i := 1 To 15 Do Begin
		w2 := w << i;
		w3 := w3 * b;
		If w2 <> w3 Then Error(31);
	End;
	w2 := w << 16; If w2 <> 1 Then Error(32);
	w2 := w << 17; If w2 <> 1 Then Error(33);

	w := $5555;
	w2 := w >> 0;
	If w2 <> $5555 Then Error(34);
	w3 := $5555;
	b := 2;
	For i := 1 To 15 Do Begin
		w2 := w >> i;
		w3 := w3 Div b;
		If w2 <> w3 Then Begin
			Error(35);
		End;
	End;
	w2 := w >> 16; If w2 <> $5555 Then Error(36);
	w2 := w >> 17; If w2 <> $5555 Then Error(37);

	w := $5555;
	w2 := w << 0;
	If w2 <> $5555 Then Error(38);
	w3 := $5555;
	b := 2;
	For i := 1 To 15 Do Begin
		w2 := w << i;
		w3 := w3 * b;
		If w2 <> w3 Then Begin
			Error(39);
		End;
	End;
	w2 := w >> 16; If w2 <> $5555 Then Error(40);
	w2 := w >> 17; If w2 <> $5555 Then Error(41);

	w := $5555;
	w2 := @w;
	If w2 <> $aaaa Then Error(42);
End;

Procedure TestBitwiseCardinal;
Begin
    d2 := $d5aad5aa;
    d3 := $13571357;
    d := d2 ! $13571357; If d <> $d7ffd7ff Then Error(43);
    d := $13571357 ! d2; If d <> $d7ffd7ff Then Error(44);
    d := $13571357 ! $d5aad5aa; If d <> $d7ffd7ff Then Error(45);
    d := $d5aad5aa ! $13571357; If d <> $d7ffd7ff Then Error(46);
    d := d2 & $13571357; If d <> $11021102 Then Error(47);
    d := $13571357 & d2; If d <> $11021102 Then Error(48);
    d := d3 & $d5aad5aa; If d <> $11021102 Then Error(49);
    d := $d5aad5aa & d3; If d <> $11021102 Then Error(50);

	d := 1;
	d2 := d << 0;
	If d2 <> 1 Then Error(51);
	d3 := 1;
	b := 2;
	For i := 1 To 31 Do Begin
		d2 := d << i;
		d3 := d3 * b;
		If d2 <> d3 Then Error(52);
	End;
	d2 := d << 32; If d2 <> 1 Then Error(53);
	d2 := d << 33; If d2 <> 1 Then Error(54);

	d := $55555555;
	d2 := d >> 0;
	If d2 <> $55555555 Then Error(55);
	d3 := $55555555;
	b := 2;
	For i := 1 To 31 Do Begin
		d2 := d >> i;
		d3 := d3 Div b;
		If d2 <> d3 Then Begin
			Error(56);
		End;
	End;
	d2 := d >> 32; If d2 <> $55555555 Then Error(57);
	d2 := d >> 33; If d2 <> $55555555 Then Error(58);

	d := $55555555;
	d2 := d << 0;
	If d2 <> $55555555 Then Error(59);
	d3 := $55555555;
	b := 2;
	For i := 1 To 31 Do Begin
		d2 := d << i;
		d3 := d3 * b;
		If d2 <> d3 Then Begin
			Error(60);
		End;
	End;
	d2 := d >> 32; If d2 <> $55555555 Then Error(61);
	d2 := d >> 33; If d2 <> $55555555 Then Error(62);

	d := $55555555;
	d2 := @d;
	If d2 <> $aaaaaaaa Then Error(63);
End;

Begin
	anyErrors := false;

	Writeln('Running');

	TestBitwiseByte;
	TestBitwiseWord;
	TestBitwiseCardinal;

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
