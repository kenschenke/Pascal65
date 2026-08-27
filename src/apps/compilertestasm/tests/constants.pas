Program ConstantsTest;

Const
    BoolConst = True;
    CharConst = 'k';
    StrConst = 'Hello World';
    ByteConst = 201;
    ShortConst = -123;
    IntConst = -12345;
    WordConst = 45678;
    LongConst = -123456;
    CardinalConst = 12345678;
    RealConst = 123.456;

Var
	anyErrors : Boolean;
    ch : Char;
    s : ShortInt;

Procedure Error(num : Integer);
Begin
    Writeln('Constants (', num, ')');
    anyErrors := true;
End;

Begin
	anyErrors := false;

	Writeln('Running constants tests');

    If BoolConst <> True Then Error(1);
    If CharConst <> 'k' Then Error(2);
    If CompareStr(StrConst, 'Hello World') <> 0 Then Error(3);
    If ByteConst <> 201 Then Error(4);
    If ShortConst <> -123 Then Error(5);
    If IntConst <> -12345 Then Error(6);
    If WordConst <> 45678 Then Error(7);
    If LongConst <> -123456 Then Error(8);
    If CardinalConst <> 12345678 Then Error(9);
    If Abs(RealConst-123.456) > 0.01 Then Error(10);

    If anyErrors Then Begin
        Write('Press any key');
        ch := GetKey;
    End;
End.
