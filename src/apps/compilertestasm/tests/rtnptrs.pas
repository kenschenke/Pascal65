Program RoutinePtrsTest;

Type
	ProcType = Procedure(num : Integer);
	FuncType = Function(num : Integer) : Integer;

Var
    anyErrors : Boolean;
    errList : String;
	ProcPtr : ProcType;
	FuncPtr : FuncType;
	i : Integer = 456;

Procedure Error(num : Integer);
Begin
    Writeln('RoutinePtrsTest (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
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

Procedure TestCallFunc(ptr : FuncType);
Begin
	i := ptr(1111);
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
    If Length(acc) < 150 Then acc := acc + 'rtnptrs:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
	Writeln('Running routine pointer tests');
	
    anyErrors := false;
    errList := '';

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

	i := 123;
	TestCallFunc(@TestFunc);
	If i <> 2222 Then Error(9);

	If CompareStr('256', WriteStr(FuncPtr(128))) <> 0 Then Error(8);

    If anyErrors Then ReportFailure;
End.
