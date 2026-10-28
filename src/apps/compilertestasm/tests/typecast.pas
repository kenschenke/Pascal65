Program TypeCastTest;

Type
    SmallNum = ShortInt;
    MediumNum = Integer;
    LargeNum = LongInt;

Var
    anyErrors : Boolean;
    ch : Char;
	b : Byte;
	s : ShortInt;
	i : Integer;
	w : Word;
	l : LongInt;
	c : Cardinal;
    snum : SmallNum;
    mnum : MediumNum;
    lnum : LargeNum;

Procedure Error(num : Integer);
Begin
    Writeln('TypeCast (', num, ')');
    anyErrors := true;
End;

Procedure TestShortAssign;
Begin
    b := Byte(-5);
    If b <> 251 Then Error(100);
    s := ShortInt(200);
    If s <> -56 Then Error(101);
End;

Procedure TestIntAssign;
Begin
    w := Word(-12345);
    If w <> 53191 Then Error(200);
    i := Integer(40000);
    If i <> -25536 Then Error(201);
End;

Procedure TestLongAssign;
Begin
    l := LongInt($ffff0000);
    If l <> -65536 Then Error(300);
    c := Cardinal(-123456);
    If c <> 4294843840 Then Error(301);
End;

Procedure TestTypeDefAssign;
Begin
   snum := SmallNum(200);
   If snum <> -56 Then Error(400);
   mnum := MediumNum(40000);
   If mnum <> -25536 Then Error(401);
   lnum := LongInt($ffff0000)
   If lnum <> -65536 Then Error(402);
End;

Begin
	anyErrors := false;

	Writeln('Running type cast tests');

	TestShortAssign;
    TestIntAssign;
    TestLongAssign;
    TestTypeDefAssign;

    If anyErrors Then Begin
        Write('Press any key');
        ch := GetKey;
    End;
End.
