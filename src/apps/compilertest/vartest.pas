Program VarTest;

Type
	MyArray = Array[1..3] Of Integer;
	MyRecord = Record
		a, b : Integer;
	End;

Var
    anyErrors : Boolean;
	a, d : MyArray;
	k, m : Integer;
	r, s : MyRecord;
    i : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('VarTest (', num, ')');
    anyErrors := true;
End;

Procedure Proc1(i : Integer; Var j : Integer);
Begin
	If i <> 11 Then Error(1);
	i := 999;
	If i <> 999 Then Error(2);
	i := 999;

	If j <> 1 Then Error(3);
	j := 123;
	If j <> 123 Then Error(4);
End;

Procedure Proc2(b : MyArray; Var c : MyArray);
Begin
	For k := 1 To 3 Do Begin
		b[k] := k * 3;
		c[k] := k * 4;
	End;
End;

Procedure Proc3(t : MyRecord; Var u : MyRecord);
Begin
	If t.a <> 1 Then Error(5);
	If t.b <> 2 Then Error(6);
	t.a := 5;
	t.b := 6;
	If t.a <> 5 Then Error(7);
	If t.b <> 6 Then Error(8);

	If u.a <> 3 Then Error(9);
	If u.b <> 4 Then Error(10);
	u.a := 7;
	u.b := 8;
	If u.a <> 7 Then Error(11);
	If u.b <> 8 Then Error(12);
End;

Begin
	Writeln('Running');
	
    anyErrors := false;

	k := 1;
	m := 11;
	Proc1(m, k);
	If m <> 11 Then Error(13);
	If k <> 123 Then Error(14);

	For k := 1 To 3 Do Begin
		a[k] := k;
		d[k] := k * 2;
	End;
	Proc2(a, d);

	For k := 1 To 3 Do Begin
		If a[k] <> k Then Error(15);
		If d[k] <> k * 4 Then Error(16);
	End;

	r.a := 1;
	r.b := 2;
	s.a := 3;
	s.b := 4;
	Proc3(r, s);

	If r.a <> 1 Then Error(17);
	If r.b <> 2 Then Error(18);
	If s.a <> 7 Then Error(19);
	If s.b <> 8 Then Error(20);

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
