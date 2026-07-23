Program ScopeTest;

Var
    anyErrors : Boolean;
	i, j, z : Integer;
	a : Boolean;

Procedure Error(num : Integer);
Begin
    Writeln('ScopeTest (', num, ')');
    anyErrors := true;
End;

Procedure Proc1(i : Integer);
Var
	k : Integer;
	a : Char;

	Procedure Proc2(j : Integer);
	Var
		a : Integer;
	Begin
		a := 16;
		If j <> 8 Then Error(1);
		If k <> 7 Then Error(2);
		k := 14;
		j := 9;
		i := 13;
		z := 15;
		If a <> 16 Then Error(3);
	End;

Begin (* Proc1 *)
	a := 'x';
	If i <> 5 Then Error(4);
	i := 6;
	k := 7;
	Proc2(8);
	If j <> 10 Then Error(5);
	If k <> 14 Then Error(6);
	If i <> 13 Then Error(7);
	If a <> 'x' Then Error(8);
	j := 12;
End;

(* Main *)
Begin
	Writeln('Running');
	
	a := True;
	i := 5;
	j := 10;
	Proc1(i);
	If i <> 5 Then Error(9);
	If j <> 12 Then Error(10);
	If z <> 15 Then Error(11);
	If Not a Then Error(12);

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
