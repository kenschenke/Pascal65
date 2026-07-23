Program TrigTest;

Type
	RealArr = Array[1..12] Of Real;

Var
	anyErrors : Boolean;
	ch : Char;

Procedure Error(num : Integer);
Begin
    Writeln('Trig (', num, ')');
    anyErrors := true;
End;

Procedure TestCos;
Var
	i : Integer;
	CosAngles : RealArr =
		(0.541052, 0.90757, 1.570795, 2.1293, 2.635445, 3.14159,
		3.612829, 4.328413, 4.712385, 5.201077, 5.881755, 6.265727);
	CosResult : RealArr =
		(0.881358, 0.6661728, 0.0, -0.5846914, -0.8961728, -1.0,
		-0.91, -0.4291358, 0.0, 0.5254321, 0.9346914, 0.9998765);
Begin
	For i := 1 To 12 Do
		If Abs(Cos(CosAngles[i]) - CosResult[i]) > 0.001 Then Error(1);
End;

Procedure TestSin;
Var
	i : Integer;
	SinAngles : RealArr = 
		(0.383972, 1.308996, 1.570795, 1.919861, 2.792524, 3.14159, 
		3.473202, 4.118974, 4.712385, 5.026544, 5.602502, 6.265727);
	SinResult : RealArr =
		(0.429135802, 0.97222222, 1.0, 0.950617284, 0.395061728, 0.0,
		-0.37765432, -0.85728395, -1.0, -0.96, -0.67888889, -0.02209877);
Begin
	For i := 1 To 12 Do
		If Abs(Sin(SinAngles[i]) - SinResult[i]) > 0.001 Then Error(2);
End;

Begin
	anyErrors := false;

	Writeln('Running');

	TestCos;
	TestSin;

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
