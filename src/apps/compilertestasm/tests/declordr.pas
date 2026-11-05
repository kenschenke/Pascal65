Program DeclOrderTest;

// The Const, Type, Var and routine sections can come in any order and
// more than once, in the program and in a routine.

Type
    Range = 1..5;

Const
    First = 3;

Var
    anyErrors : Boolean;
    errList : String;

Type
    Arr = Array[Range] Of Integer;

Var
    a : Arr;

Const
    Name = 'decl';

Procedure Error(num : Integer);
Begin
    Writeln('DeclOrder (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Function Twice(n : Integer) : Integer;
Begin
    Twice := n * 2;
End;

// Declared after a routine
Var
    later : Integer;

Const
    Last = 9;

Type
    Letter = 'a'..'e';

Procedure TestLocal;
Var
    i : Integer;
Const
    Step = 2;
Type
    Pair = Array[1..2] Of Integer;
Var
    p : Pair;
    l : Letter;
Function Add(x, y : Integer) : Integer;
Begin
    Add := x + y;
End;
Const
    Extra = 10;
Begin
    p[1] := Step;
    i := First;
    p[2] := i + Step;
    If p[1] + p[2] <> 7 Then Error(200);
    i := Add(Extra, Last);
    If i <> 19 Then Error(201);
    l := 'c';
    If Ord(l) - Ord('a') <> 2 Then Error(202);
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
    If Length(acc) < 150 Then acc := acc + 'declordr:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Var
    i : Integer;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running declaration order tests');

    For i := 1 To 5 Do a[i] := Twice(i);
    If a[First] <> 6 Then Error(100);
    later := Last;
    If later <> 9 Then Error(101);
    If CompareStr(Name, 'decl') <> 0 Then Error(102);
    If a[5] <> 10 Then Error(103);

    TestLocal;

    If anyErrors Then ReportFailure;
End.
