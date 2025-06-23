Program BitwiseTest;

Var
	anyErrors : Boolean;
	ch : Char;
	i : Integer;
	b : Byte;
	d, d2, d3 : Cardinal;

Procedure Error(num : Integer);
Begin
    Writeln('Bitwise (', num, ')');
    anyErrors := true;
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
	d2 := Not d;
	If d2 <> $aaaaaaaa Then Error(63);
End;

Begin
	anyErrors := false;

	Writeln('Running');

	TestBitwiseCardinal;

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
