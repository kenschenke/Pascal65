Program AssignTest;

Var
	anyErrors : Boolean;
    ch : Char;
	b : Byte;
	s : ShortInt;
	i : Integer;
	w : Word;
	l : LongInt;
	c : Cardinal;

Procedure Error(num : Integer);
Begin
    Writeln('Assign (', num, ')');
    anyErrors := true;
End;

Procedure TestShortAssign;
Begin
	b := 5;
    If b <> 5 Then Error(100);
    b := b + 100;  // ***********************************
    If b <> 105 Then Error(101);
    b := 192;
    If b <> 192 Then Error(102);
    s := -5;
    If s <> -5 Then Error(103);
    s := s + 100;
    If s <> 95 Then Error(104);
    s := 126;
    If s <> 126 Then Error(105);
End;

Procedure TestIntAssign;
Begin
    w := 5;
    If w <> 5 Then Error(200);
    w := w + 1000;  // *******************************************
    If w <> 1005 Then Error(201);
    w := 1024;
    If w <> 1024 Then Error(202);
    w := w + 1000;  // *******************************************
    If w <> 2024 Then Error(203);
    w := 40000;
    If w <> 40000 Then Error(204);
    w := w + 10000;  // ********************************************
    If w <> 50000 Then Error(205);
    i := -5;
    If i <> -5 Then Error(206);
    i := i + 1000;
    If i <> 995 Then Error(207);
    i := -1234;
    If i <> -1234 Then Error(208);
    i := i + 10000;
    If i <> 8766 Then Error(209);
    i := -12345;
    If i <> -12345 Then Error(210);
End;

Procedure TestLongAssign;
Begin
    c := 5;
    If c <> 5 Then Error(300);
    c := c + 123;
    If c <> 128 Then Error(301);
    c := 12345;
    If c <> 12345 Then Error(302);
    c := c + 10000;
    If c <> 22345 Then Error(303);
    c := 123456;
    If c <> 123456 Then Error(304);
    c := c + 100000;
    If c <> 223456 Then Error(305);
    l := -5;
    If l <> -5 Then Error(306);
    l := l + 100;
    If l <> 95 Then Error(307);
    l := -12345;
    If l <> -12345 Then Error(308);
    l := l + 10000;
    If l <> -2345 Then Error(309);
    l := -123456;
    If l <> -123456 Then Error(310);
    l := l + 100000;
    If l <> -23456 Then Error(311);
End;

Begin
	anyErrors := false;

	Writeln('Running');

	TestShortAssign;
    TestIntAssign;
    TestLongAssign;

    If anyErrors Then Begin
        Write('Press any key');
        ch := GetKey;
    End;
End.
