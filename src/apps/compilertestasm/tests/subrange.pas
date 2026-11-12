Program SubrangeTest;

// Subranges whose limits are integers of different types, constants,
// characters or enumeration values. A subrange variable is the integer
// type that holds both limits, so it keeps every value in the range. The
// arrays come after the enumeration subrange variable col, which once
// had no storage and moved every variable after it.

Const
    Lo = -1000;
    Hi = 1000;

Type
    Small = 1..1000;
    Signed = -5..5;
    Wide = 1..100000;
    ByConst = Lo..Hi;
    Color = (Red, Green, Blue);
    Warm = Red..Green;
    Letter = 'a'..'z';

Var
    anyErrors : Boolean;
    errList : String;
    s : Small;
    g : Signed;
    w : Wide;
    c : ByConst;
    col : Warm;
    ch : Letter;
    arr : Array[-5..300] Of Integer;
    a1 : Array[-300..300] Of Integer;
    a2 : Array[1..300] Of Integer;
    a3 : Array[-5..5] Of Integer;
    i : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('Subrange (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure TestValues;
Begin
    s := 1000;
    If s <> 1000 Then Error(1);
    g := -5;
    If g <> -5 Then Error(2);
    If g >= 0 Then Error(3);
    w := 100000;
    If w <> 100000 Then Error(4);
    c := -1000;
    If c <> -1000 Then Error(5);
    c := Hi;
    If c <> 1000 Then Error(6);
    col := Green;
    If col <> Green Then Error(7);
    ch := 'q';
    If ch <> 'q' Then Error(8);
End;

Procedure TestArray;
Begin
    arr[-5] := 7;
    arr[300] := 9;
    If arr[-5] <> 7 Then Error(10);
    If arr[300] <> 9 Then Error(11);
    If Low(arr) <> -5 Then Error(12);
    If High(arr) <> 300 Then Error(13);
    If Low(a1) <> -300 Then Error(14);
    If High(a1) <> 300 Then Error(15);
    If Low(a2) <> 1 Then Error(16);
    If High(a2) <> 300 Then Error(17);
    If Low(a3) <> -5 Then Error(18);
    If High(a3) <> 5 Then Error(19);
End;

Procedure TestLoops;
Begin
    i := 0;
    For g := -5 To 5 Do i := i + g;
    If i <> 0 Then Error(20);
    i := 0;
    For s := 998 To 1000 Do i := i + 1;
    If i <> 3 Then Error(21);
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
    If Length(acc) < 150 Then acc := acc + 'subrange:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running subrange tests');

    TestValues;
    TestArray;
    TestLoops;

    If anyErrors Then ReportFailure;
End.
