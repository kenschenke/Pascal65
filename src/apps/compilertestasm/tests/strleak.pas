(* String Function Result Tests *)

Program StrLeak;

// A function's String result is a new string. Assigning it, passing it
// as a parameter or using it in an expression must free it, or these
// loops run out of memory and the chain stops.

Const
    Loops = 3000;

Var
    anyErrors : Boolean;
    errList : String;
    s : String;
    i, k : Integer;
    n : Byte;

Procedure Error(num : Integer);
Begin
    Writeln('StrLeak (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
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
    If Length(acc) < 150 Then acc := acc + 'strleak:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Function Twice(x : String) : String;
Begin
    Twice := x + x;
End;

Function Same(x : String) : String;
Begin
    Same := x;
End;

Begin
    Writeln('Running string leak tests');

    anyErrors := false;
    errList := '';

    // A library function's result assigned to a variable
    s := 'apple';
    For i := 1 To Loops Do s := UpCase(s);
    If CompareStr(s, 'APPLE') <> 0 Then Error(1);

    // One library function's result passed to another
    s := ' pear ';
    For i := 1 To Loops Do s := Trim(UpCase(s));
    If CompareStr(s, 'PEAR') <> 0 Then Error(2);

    // A Pascal function's result
    For i := 1 To Loops Do s := Same(s);
    If CompareStr(s, 'PEAR') <> 0 Then Error(3);

    // A result passed as a parameter
    n := 0;
    For i := 1 To Loops Do n := Length(UpCase(s));
    If n <> 4 Then Error(4);

    // A result passed to CompareStr, and in a concatenation
    For i := 1 To Loops Do Begin
        If CompareStr(UpCase(s), 'PEAR') <> 0 Then Error(5);
        If Length(Twice(s) + LowerCase(s)) <> 12 Then Error(6);
    End;

    // A comparison frees a concatenation or a function's result, on
    // either side
    k := 0;
    For i := 1 To Loops Do Begin
        If s + 'S' = 'PEARS' Then k := k + 1;
        If 'PEARS' <> s + 'S' Then Error(7);
        If Same(s) = s Then k := k + 1;
        If s <> Same(s) Then Error(8);
        If Not (Twice(s) < Same(s) + 'Z') Then Error(9);
        If Not (UpCase('pears') > s + 'R') Then Error(10);
    End;
    If k <> 2 * Loops Then Error(11);

    If anyErrors Then ReportFailure;
End.
