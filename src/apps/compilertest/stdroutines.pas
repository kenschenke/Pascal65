(* Standard Routine Tests *)

Program StdRoutines;
Type
    Months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);

Var
    anyErrors : Boolean;
    c : Char;
    i : Integer;
    m : Months;
    r : Real;

Procedure Error(num : Integer);
Begin
    Writeln('StdRoutines (', num, ')');
    anyErrors := true;
End;

Begin
    anyErrors := false;

    Writeln('Running');

    i := -1008;
    If Abs(-572) <> 572 Then Error(1);
    If Abs(513) <> 513 Then Error(2);
    If Abs(i) <> 1008 Then Error(3);

    i := 514;
    If Odd(2012) Then Error(4);
    If Odd(i) Then Error(5);

    i := 66;
    If Chr(65) <> 'a' Then Error(6);
    If Chr(i) <> 'b' Then Error(7);

    i := 23;
    If Sqr(21) <> 441 Then Error(8);
    If Sqr(i) <> 529 Then Error(9);

    r := 123.51;
    If Round(57.21) <> 57 Then Error(10);
    If Round(r) <> 124 Then Error(11);

    If Trunc(57.8) <> 57 Then Error(12);
    If Trunc(r) <> 123 Then Error(13);

    m := May;
    i := 1234;
    c := 'c';
    If Ord(Oct) <> 9 Then Error(14);
    If Ord(m) <> 4 Then Error(15);
    If Ord(i) <> 1234 Then Error(16);
    If Ord(c) <> 67 Then Error(17);
    If Ord('b') <> 66 Then Error(18);

    If Pred(m) <> Apr Then Error(19);
    If Pred(Apr) <> Mar Then Error(20);
    If Pred(c) <> 'b' Then Error(21);
    If Pred('x') <> 'w' Then Error(22);
    If Pred(i) <> 1233 Then Error(23);
    If Pred(1225) <> 1224 Then Error(24);

    If Succ(m) <> Jun Then Error(25);
    If Succ(Sep) <> Oct Then Error(26);
    If Succ(c) <> 'd' Then Error(27);
    If Succ('w') <> 'x' Then Error(28);
    If Succ(i) <> 1235 Then Error(29);
    If Succ(1244) <> 1245 Then Error(30);

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
