Program NamedIndexTest;

// Arrays whose index is a declared (named) type: a subrange, an enumeration
// or a constant number of elements. The bounds in each array's runtime
// header come from the named type. Indexing checks them and a character
// array takes its length from them.

Const
    Count = 4;

Type
    Range = 5..9;
    NegRange = -3..3;
    Letters = 'a'..'e';
    Color = (Red, Green, Blue);
    RangeArr = Array[Range] Of Integer;
    Point = Record
        x, y : Integer;
    End;

Var
    anyErrors : Boolean;
    errList : String;
    a : Array[Range] Of Integer;
    after : Array[Range] Of Integer;
    neg : Array[NegRange] Of Integer;
    chars : Array[Letters] Of Char;
    colors : Array[Color] Of Integer;
    counted : Array[Count] Of Integer;
    init : Array[Range] Of Integer = (51, 61, 71, 81, 91);
    strs : Array[Range] Of String = ('five', 'six');
    points : Array[Range] Of Point;
    grid : Array[Range, Color] Of Integer;
    x, y : RangeArr;
    i : Integer;
    str : String;

Procedure Error(num : Integer);
Begin
    Writeln('NamedIdx (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

// Filling the whole of a must not reach into the array declared after it.
Procedure TestSubrange;
Begin
    For i := 5 To 9 Do after[i] := -i;
    For i := 5 To 9 Do a[i] := i * 10;
    For i := 5 To 9 Do
        If a[i] <> i * 10 Then Error(100);
    For i := 5 To 9 Do
        If after[i] <> -i Then Error(101);
    If a[5] <> 50 Then Error(102);
    If a[9] <> 90 Then Error(103);
End;

Procedure TestNegative;
Begin
    For i := -3 To 3 Do neg[i] := i * 2;
    If neg[-3] <> -6 Then Error(200);
    If neg[0] <> 0 Then Error(201);
    If neg[3] <> 6 Then Error(202);
End;

// Assigning a character array to a string uses the header's length
Procedure TestChars;
Begin
    chars['a'] := 'v';
    chars['b'] := 'w';
    chars['c'] := 'x';
    chars['d'] := 'y';
    chars['e'] := 'z';
    str := chars;
    If Length(str) <> 5 Then Error(300);
    If CompareStr(str, 'vwxyz') <> 0 Then Error(301);
End;

Procedure TestEnum;
Begin
    colors[Red] := 1;
    colors[Green] := 2;
    colors[Blue] := 3;
    If colors[Red] <> 1 Then Error(400);
    If colors[Green] <> 2 Then Error(401);
    If colors[Blue] <> 3 Then Error(402);
End;

// Array[Count] has Count elements, indexed from 0
Procedure TestCount;
Begin
    For i := 0 To Count - 1 Do counted[i] := i + 100;
    If counted[0] <> 100 Then Error(500);
    If counted[3] <> 103 Then Error(501);
End;

Procedure TestInit;
Begin
    If init[5] <> 51 Then Error(600);
    If init[7] <> 71 Then Error(601);
    If init[9] <> 91 Then Error(602);
    If CompareStr(strs[5], 'five') <> 0 Then Error(610);
    If CompareStr(strs[6], 'six') <> 0 Then Error(611);
    If Length(strs[9]) <> 0 Then Error(612);
End;

Procedure TestRecords;
Begin
    points[5].x := 1;
    points[9].y := 99;
    If points[5].x <> 1 Then Error(700);
    If points[9].y <> 99 Then Error(701);
End;

Procedure TestGrid;
Begin
    grid[5, Red] := 51;
    grid[7, Green] := 72;
    grid[9, Blue] := 93;
    If grid[5, Red] <> 51 Then Error(800);
    If grid[7, Green] <> 72 Then Error(801);
    If grid[9, Blue] <> 93 Then Error(802);
End;

Function Sum(arr : RangeArr) : Integer;
Var j, n : Integer;
Begin
    n := 0;
    For j := 5 To 9 Do n := n + arr[j];
    Sum := n;
End;

Procedure Fill(Var arr : RangeArr);
Var j : Integer;
Begin
    For j := 5 To 9 Do arr[j] := j;
End;

// A declared array type, copied element by element and passed to routines
Procedure TestArrayType;
Begin
    Fill(x);
    If x[5] <> 5 Then Error(900);
    If x[9] <> 9 Then Error(901);
    For i := 5 To 9 Do y[i] := x[i];
    If y[5] <> 5 Then Error(902);
    If y[9] <> 9 Then Error(903);
    If Sum(x) <> 35 Then Error(904);
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
    If Length(acc) < 150 Then acc := acc + 'namedidx:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running named index tests');

    TestSubrange;
    TestNegative;
    TestChars;
    TestEnum;
    TestCount;
    TestInit;
    TestRecords;
    TestGrid;
    TestArrayType;

    If anyErrors Then ReportFailure;
End.
