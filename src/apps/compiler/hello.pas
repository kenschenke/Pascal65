Program Test;

Uses CalcArea;

Const
	Time = 5;

Var
	area : Real;

Procedure ForwardProc; Forward;

Procedure AnotherProc;
Begin
	ForwardProc;
End;

Procedure ForwardProc;
Begin
	Writeln('In ForwardProc');
End;

Begin
	Writeln('Hello, World');

	area := RectangleArea(1.5, 2.5);
	Writeln('area = ', area:0:2);
	AnotherProc;
End.
