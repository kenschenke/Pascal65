Program PointerTest;

Type
	ArrType = Array[1..5] Of Integer;
	RecType = Record
		a, b : Integer;
	End;

Var
    anyErrors : Boolean;
	ch : Char;
	i : Integer;
	j : Integer;
	iPtr, iPtr2 : ^Integer;
	arr : ArrType = (5, 10, 15, 20, 25);
	rec : RecType;
	rPtr : ^RecType;
	aPtr : ^ArrType;

Procedure Error(num : Integer);
Begin
    Writeln('PointerTest (', num, ')');
    anyErrors := true;
End;

Procedure TestByRef(Var p : ^Integer);
Begin
	p := @j;
End;

Procedure TestValueByRef(Var p : ^Integer);
Begin
	p^ := 21321;
End;

Function ReturnValue(num : Integer) : Integer;
Begin
	ReturnValue := num;
End;

Function ReturnPtrValue(p : ^Integer) : Integer;
Begin
	ReturnPtrValue := p^;
End;

Function ReturnPtr : ^Integer;
Begin
	ReturnPtr := @i;
End;

Begin
	Writeln('Running');
	
    anyErrors := false;

	// Test accessing variable through pointer
	i := 12345;
	iPtr := @i;
	If iPtr^ <> 12345 Then Error(1);

	// Test modifying variable through pointer
	iPtr^ := 23456;
	If i <> 23456 Then Error(2);

	// Test passing dereferenced pointer to write
	If CompareStr(WriteStr(iPtr^), '23456') <> 0 Then Error(3);

	// Test passing pointer to procedure by reference
	j := 21212;
	TestByRef(iPtr);
	If iPtr^ <> 21212 Then Error(4);

	// Pass dereferenced value to routine
	i := 12345;
	iPtr := @i;
	If ReturnValue(iPtr^) <> 12345 Then Error(5);

	// Pass pointer by value to routine
	If ReturnPtrValue(iPtr) <> 12345 Then Error(6);

	// Pass a pointer by reference to a procedure that updates the value
	TestValueByRef(iPtr);
	If iPtr^ <> 21321 Then Error(7);
	If i <> 21321 Then Error(8);

	// Test function returning dereferenced value
	i := 12345;
	If ReturnPtrValue(@i) <> 12345 Then Error(9);

	// Test function returning pointer
	iPtr := ReturnPtr;
	If iPtr^ <> 12345 Then Error(10);

	// Test pointer to array elements, inc/dec, and pointer math
	iPtr := @arr[1];
	Inc(iPtr, 2);
	If iPtr^ <> 15 Then Error(11);
	Dec(iPtr);
	If iPtr^ <> 10 Then Error(12);
	iPtr := @arr[1];
	iPtr := iPtr + 3;
	If iPtr^ <> 20 Then Error(13);
	iPtr := iPtr - 2;
	If iPtr^ <> 10 Then Error(14);

	// Test assigning one pointer to another
	i := 12345;
	iPtr := @i;
	iPtr2 := iPtr;
	If iPtr2^ <> i Then Error(15);

	// Test pointer comparison
	If iPtr <> iPtr2 Then Error(16);
	iPtr2 := @j;
	If iPtr = iPtr2 Then Error(17);

	iPtr := @arr[1];
	iPtr2 := @arr[2];
	If iPtr >= iPtr2 Then Error(18);
	If iPtr2 < iPtr Then Error(19);

	// Test comparing pointer to address of variable
	iPtr := @i;
	If iPtr <> @i Then Error(20);

	// Test pointer to record
	rPtr := @rec;
	rec.a := 12345;
	rec.b := 23456;
	If (rPtr^.a <> 12345) Or (rPtr^.b <> 23456) Then Error(21);

	rPtr^.a := 12121;
	rPtr^.b := 21212;
	If (rec.a <> 12121) Or (rec.b <> 21212) Then Error(22);

	// Test pointer to array
	aPtr := @arr;
	For i := 1 To 5 Do Begin
		If aPtr^[i] <> i*5 Then Error(23);
		aPtr^[i] := i * 6;
	End;
	For i := 1 To 5 Do
		If arr[i] <> i * 6 Then Error(24);
	
	// Test comparison to nil
	If iPtr = nil Then Error(25);
	iPtr := nil;
	If iPtr <> nil Then Error(26);

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
