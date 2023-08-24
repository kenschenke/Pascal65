Program RecArray;
Type
	Rec = Record
		a, b : Integer;
		ar : Array[1..10] Of Integer;
	End;
	Rec3 = Record
		a, b, c : Integer;
	End;
	GreatGrandChild = Record
		i, j : Integer;
	End;
	GrandChildRecord = Record
		g, h : Integer;
		ggc : GreatGrandChild;
	End;
	Child = Record
		x, y : Integer;
		gc : GrandChildRecord;
	End;
	Parent = Record
		c, d : Integer;
		ch : Child;
		e, f : Integer;
	End;
Var
    anyErrors : Boolean;
	i , j : integer;
	myRec : Rec;
	myRec3 : Rec3;
	myParent : Parent;
	ar1 : Array[1..10] Of Rec;
	ar2 : Array[1..10,1..3] Of Integer;
	ar3 : Array[1..10] Of Rec3;

Procedure Error(num : Integer);
Begin
    Writeln('RecArray (', num, ')');
    anyErrors := true;
End;

Begin
	Writeln('Running');
	
	myParent.c := 1234;
	myParent.d := 2345;
	myParent.ch.x := 3456;
	myParent.ch.y := 4567;
	myParent.ch.gc.ggc.i := 3434;
	myParent.ch.gc.ggc.j := 4545;
	myParent.ch.gc.g := 1212;
	myParent.ch.gc.h := 2323;
	myParent.e := 5678;
	myParent.f := 6789;

	For i := 1 To 10 Do Begin
		For j := 1 To 3 Do Begin
			ar2[i][j] := i * 10 + j;
		End;
	End;

	For i := 1 To 10 Do
		myRec.ar[i] := i;

	For i := 1 To 10 Do Begin
		ar1[i].a := i * 3;
		ar1[i].b := i * 4;
		For j := 1 To 10 Do Begin
			ar1[i].ar[j] := i * 10 + j;
		End;
	End;

	For i := 1 To 10 Do Begin
		ar3[i].a := i * 10 + 1;
		ar3[i].b := i * 10 + 2;
		ar3[i].c := i * 10 + 3;
	End;

	If myParent.c <> 1234 Then Error(1);
	If myParent.d <> 2345 Then Error(2);
	If myParent.ch.x <> 3456 Then Error(3);
	If myParent.ch.y <> 4567 Then Error(4);
	If myParent.ch.gc.ggc.i <> 3434 Then Error(5);
	If myParent.ch.gc.ggc.j <> 4545 Then Error(6);
	If myParent.ch.gc.g <> 1212 Then Error(7);
	If myParent.ch.gc.h <> 2323 Then Error(8);
	If myParent.e <> 5678 Then Error(9);
	If myParent.f <> 6789 Then Error(10);

	For i := 1 To 10 Do Begin
		If ar1[i].a <> i * 3 Then Error(11);
		If ar1[i].b <> i * 4 Then Error(12);
		For j := 1 To 10 Do Begin
			If ar1[i].ar[j] <> i * 10 + j Then
				Error(13);
		End;
	End;

	For i := 1 To 10 Do Begin
		For j := 1 To 3 Do Begin
			If ar2[i][j] <> i * 10 + j Then Error(14);
		End;
	End;

	For i := 1 To 10 Do Begin
		If myRec.ar[i] <> i Then Error(15);
	End;

	For i := 1 To 10 Do Begin
		If ar3[i].a <> i * 10 + 1 Then Error(16);
		If ar3[i].b <> i * 10 + 2 Then Error(17);
		If ar3[i].c <> i * 10 + 3 Then Error(18);
	End;

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
