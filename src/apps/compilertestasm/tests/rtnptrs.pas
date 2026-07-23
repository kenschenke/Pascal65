Program RoutinePtrsTest;

Type
	ProcType = Procedure(num : Integer);
	FuncType = Function(num : Integer) : Integer;

Var
    anyErrors : Boolean;
	ch : Char;
	ProcPtr : ProcType;
	FuncPtr : FuncType;
	i : Integer = 456;

Procedure Error(num : Integer);
Begin
    Writeln('RoutinePtrsTest (', num, ')');
    anyErrors := true;
End;

Procedure TestCaller(ptr : ProcType);
Begin
	ptr(123);
End;

Procedure TestProc(num : Integer);
Begin
	If num <> 123 Then Error(1);
	If i <> 456 Then Error(2);
	i := 789;
End;

Function TestFunc(num : Integer) : Integer;
Begin
	TestFunc := num * 2;
End;

Begin
	Writeln('Running');
	
    anyErrors := false;

	ProcPtr := @TestProc;
	ProcPtr(123);
	If i <> 789 Then Error(3);

	FuncPtr := @TestFunc;
	If FuncPtr(12) <> 24 Then Error(4);

	i := 456;
	TestCaller(ProcPtr);
	If i <> 789 Then Error(6);

	i := 456;
	TestCaller(@TestProc);
	If i <> 789 Then Error(7);

	If CompareStr('256', WriteStr(FuncPtr(128))) <> 0 Then Error(8);

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
