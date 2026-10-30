Program TypeCastTest;

Type
    SmallNum = ShortInt;
    MediumNum = Integer;
    LargeNum = LongInt;

Var
    anyErrors : Boolean;
    errList : String;
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
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
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

Procedure ReportFailure;
Var
    f : Text;
    acc : String;
Begin
    // Keep entries from earlier tests
    acc := '';
    Assign(f, 'testfailed');
    Reset(f);
    If IOResult = 0 Then Readln(f, acc);
    Close(f);
    If Length(acc) < 150 Then acc := acc + 'typecast:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
	anyErrors := false;
	errList := '';

	Writeln('Running type cast tests');

	TestShortAssign;
    TestIntAssign;
    TestLongAssign;
    TestTypeDefAssign;

    If anyErrors Then ReportFailure;
End.
