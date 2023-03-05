Program RoutineTest(input, output);

Type
    en = (one, two, three, four, five);
    ar = Array[1..10] Of integer;
    rec = Record
        i : integer;
        r : real;
    End;

Procedure Scalar1(i : integer; r : real; b : boolean; c : char);
Begin
    writeln(i);
End;

Procedure Proc2(r : rec; a : ar; e : en);
Begin
    writeln(r.i);
End;

Function FuncInt(i : integer) : integer;
Begin
    FuncInt := i * 2;
End;

Function FuncReal(r : real) : real;
Begin
    FuncReal := r + 0.5001;
End;

Function FuncBool(b : boolean) : boolean;
Begin
    FuncBool := Not b;
End;

Function FuncChar(c : char) : char;
Begin
    FuncChar := Chr(Ord(c) + 1);
End;

Function FuncEnum(e : en) : en;
Begin
    FuncEnum := one;
End;

Procedure VarScalar(Var i : integer; Var r : real;
    Var b : boolean; Var c : char);
Begin
    i := i * 2;
    r := -1.01;
    b := Not b;
    c := Chr(Ord(c) + 1);
End;

Procedure VarEnum(Var e : en);
Begin
    e := one;
End;

Procedure VarProc(Var a : ar; Var r : rec);
Begin
    a[0] := a[0] * 2;
    r.i := r.i + 1;
End;

Begin
End.
