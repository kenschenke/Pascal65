Program VarTest;

Type
    Days = (Mon, Tue, Wed, Thu, Fri, Sat, Sun);
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
	c, e : Char;
    g, h : Days;
    u, v : Real;

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

Procedure Proc4(m : Char; Var n : Char);
Begin
	If m <> 'c' Then Error(21);
	If n <> 'd' Then Error(22);
	m := 'f';
	n := 'e';
End;

Procedure Proc5(o : Days; Var p : Days);
Begin
    If o <> Tue Then Error(25);
    If p <> Wed Then Error(26);
    o := Fri;
    p := Thu;
End;

Procedure Proc6(w : Real; Var x : Real);
Begin
    If Abs(w - 1.23) > 0.01 Then Error(29);
    If Abs(x - 5.45) > 0.01 Then Error(30);
    w := 10.97;
    x := 15.5;
End;

Procedure Proc7(Var r7 : MyRecord);
Begin
	r7.a := 3456;
	r7.b := 4567;
End;

Procedure Proc8(Var r8 : MyRecord);
Begin
	Proc7(r8);
End;

Procedure Proc9(Var a9 : MyArray);
Begin
	a9[1] := 4;
	a9[2] := 5;
	a9[3] := 6;
End;

Procedure Proc10(Var a10 : MyArray);
Begin
	Proc9(a10);
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

	c := 'c';
	e := 'd';
	Proc4(c, e);
	If c <> 'c' Then Error(23);
	If e <> 'e' Then Error(24);

    g := Tue;
    h := Wed;
    Proc5(g, h);
    If g <> Tue Then Error(27);
    If h <> Thu Then Error(28);

    u := 1.23;
    v := 5.45;
    Proc6(u, v);
    If Abs(u - 1.23) > 0.01 Then Error(31);
    If Abs(v - 15.5) > 0.01 Then Error(32);

	r.a := 1234;
	r.b := 2345;
	Proc8(r);
	If r.a <> 3456 Then Error(33);
	If r.b <> 4567 Then Error(34);

	a[1] := 1;
	a[2] := 2;
	a[3] := 3;
	Proc10(a);
	If a[1] <> 4 Then Error(35);
	If a[2] <> 5 Then Error(36);
	If a[3] <> 6 Then Error(37);

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
