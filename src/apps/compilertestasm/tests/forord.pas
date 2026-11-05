Program ForOrdinalTest;

// For loops whose control variable is a Char, an enumeration or a subrange,
// counting up and down, and loops that end at the limits of their type.

Type
    Color = (Red, Green, Blue, Yellow);
    Letters = 'a'..'z';
    Small = 1..10;

Var
    anyErrors : Boolean;
    errList : String;
    c : Char;
    k : Color;
    lt : Letters;
    sm : Small;
    str : String;
    n : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('ForOrd (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure TestChar;
Var
    lo, hi : Char;
Begin
    str := '';
    For c := 'a' To 'e' Do str := str + c;
    If CompareStr(str, 'abcde') <> 0 Then Error(100);

    str := '';
    For c := 'e' Downto 'a' Do str := str + c;
    If CompareStr(str, 'edcba') <> 0 Then Error(101);

    // A loop whose final value is before its initial value never runs
    n := 0;
    For c := 'x' To 'w' Do n := n + 1;
    If n <> 0 Then Error(102);

    n := 0;
    For c := 'q' To 'q' Do n := n + 1;
    If n <> 1 Then Error(103);

    // The limits can be any Char expression
    lo := 'k';
    hi := 'n';
    str := '';
    For c := lo To hi Do str := str + c;
    If CompareStr(str, 'klmn') <> 0 Then Error(104);

    str := '';
    For c := Succ(lo) To Pred(hi) Do str := str + c;
    If CompareStr(str, 'lm') <> 0 Then Error(105);
End;

Procedure TestEnum;
Begin
    n := 0;
    For k := Red To Yellow Do n := n * 10 + Ord(k) + 1;
    If n <> 1234 Then Error(200);

    n := 0;
    For k := Yellow Downto Red Do n := n * 10 + Ord(k) + 1;
    If n <> 4321 Then Error(201);

    n := 0;
    For k := Succ(Red) To Pred(Yellow) Do n := n * 10 + Ord(k);
    If n <> 12 Then Error(202);

    n := 0;
    For k := Blue To Green Do n := n + 1;
    If n <> 0 Then Error(203);
End;

Procedure TestCharSubrange;
Begin
    str := '';
    For lt := 'p' To 't' Do str := str + lt;
    If CompareStr(str, 'pqrst') <> 0 Then Error(300);

    str := '';
    For lt := 'c' Downto 'a' Do str := str + lt;
    If CompareStr(str, 'cba') <> 0 Then Error(301);
End;

Procedure TestIntSubrange;
Begin
    n := 0;
    For sm := 1 To 10 Do n := n + sm;
    If n <> 55 Then Error(400);

    n := 0;
    For sm := 10 Downto 7 Do n := n + sm;
    If n <> 34 Then Error(401);
End;

// Local control variables and nested loops
Procedure TestLocal;
Var
    ch : Char;
    col : Color;
    l : Letters;
    count : Integer;
Begin
    count := 0;
    For col := Red To Blue Do
        For ch := 'a' To 'c' Do count := count + 1;
    If count <> 9 Then Error(500);

    str := '';
    For col := Green Downto Red Do
        For l := 'x' To 'y' Do str := str + l;
    If CompareStr(str, 'xyxy') <> 0 Then Error(501);

    str := '';
    For ch := 'b' Downto 'a' Do
        For col := Red To Green Do str := str + ch;
    If CompareStr(str, 'bbaa') <> 0 Then Error(502);
End;

// Loops that end at the first or last value of their type. The loop must
// stop there and not step past it, which would wrap around.
Procedure TestBounds;
Var
    b : Byte;
    w : Word;
    sh : ShortInt;
Begin
    n := 0;
    For b := 3 Downto 0 Do n := n + 1;
    If n <> 4 Then Error(600);

    n := 0;
    For b := 250 To 255 Do n := n + 1;
    If n <> 6 Then Error(601);

    n := 0;
    For w := 2 Downto 0 Do n := n + 1;
    If n <> 3 Then Error(602);

    n := 0;
    For sh := 125 To 127 Do n := n + 1;
    If n <> 3 Then Error(603);

    n := 0;
    For sh := -126 Downto -128 Do n := n + 1;
    If n <> 3 Then Error(604);

    n := 0;
    For k := Yellow Downto Red Do n := n + 1;
    If n <> 4 Then Error(605);
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
    If Length(acc) < 150 Then acc := acc + 'forord:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running For loop ordinal tests');

    TestChar;
    TestEnum;
    TestCharSubrange;
    TestIntSubrange;
    TestLocal;
    TestBounds;

    If anyErrors Then ReportFailure;
End.
