(* String Comparison Tests *)

Program StrComp;

// The relational operators on strings (plans/stringopers.md): every
// operator, each operand form on each side, the results in each kind of
// Boolean context, and agreement with CompareStr. Strings compare byte by
// byte in PETSCII order, so 'a' ($41) sorts before 'A' ($C1).

Const
    K = 'abc';

Type
    Pair = Record
        s : String;
        a : Array[1..3] Of Char;
    End;
    Letter = 'a'..'z';

Var
    anyErrors : Boolean;
    errList : String;
    s, t, u : String;
    long1, long2, long3 : String;
    r : Pair;
    e : Array[1..3] Of String;
    a3 : Array[1..3] Of Char = ('a', 'b', 'c');
    a4 : Array[1..4] Of Char = ('a', 'b', 'c', 'd');
    b3 : Array[0..2] Of Char = ('a', 'b', 'd');
    big : Array[1..255] Of Char;
    c, d : Char;
    l : Letter;
    ps : ^String;
    b : Boolean;
    i, n : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('StrComp (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'strcomp:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

// A Boolean argument
Procedure Expect(num : Integer; got, want : Boolean);
Begin
    If got <> want Then Error(num);
End;

// Each operator on x and y, which must sort as want gives (its sign), and
// agree with CompareStr(x, y) op 0
Procedure CheckDir(num : Integer; x, y : String; want : ShortInt);
Var
    cmp : ShortInt;
Begin
    If (x < y) <> (want < 0) Then Error(num);
    If (x <= y) <> (want <= 0) Then Error(num + 1);
    If (x > y) <> (want > 0) Then Error(num + 2);
    If (x >= y) <> (want >= 0) Then Error(num + 3);
    If (x = y) <> (want = 0) Then Error(num + 4);
    If (x <> y) <> (want <> 0) Then Error(num + 5);
    cmp := CompareStr(x, y);
    If (x < y) <> (cmp < 0) Then Error(num + 6);
    If (x <= y) <> (cmp <= 0) Then Error(num + 6);
    If (x > y) <> (cmp > 0) Then Error(num + 6);
    If (x >= y) <> (cmp >= 0) Then Error(num + 6);
    If (x = y) <> (cmp = 0) Then Error(num + 6);
    If (x <> y) <> (cmp <> 0) Then Error(num + 6);
End;

// Both orders
Procedure CheckPair(num : Integer; x, y : String; want : ShortInt);
Begin
    CheckDir(num, x, y, want);
    CheckDir(num + 10, y, x, -want);
End;

Procedure TestPairs;
Begin
    CheckPair(100, 'abc', 'abc', 0);        // Equal
    CheckPair(120, 'abc', 'abcd', -1);      // A prefix
    CheckPair(140, '', '', 0);              // Empty
    CheckPair(160, '', 'a', -1);
    CheckPair(180, 'abc', 'xbc', -1);       // The first character
    CheckPair(200, 'abc', 'abd', -1);       // The last character
    CheckPair(220, 'a', 'A', -1);           // PETSCII order
    CheckPair(240, 'Zebra', 'apple', 1);
    CheckPair(260, Chr(200) + 'x', Chr(65) + 'x', 1);   // The high bit
    CheckPair(280, Chr(255), Chr(254), 1);
    CheckPair(300, long1, long2, -1);       // 255 characters
    CheckPair(320, long1, long1, 0);
    CheckPair(340, long1, long3, 1);        // 255 against 254
    CheckPair(360, s, t, -1);               // Variables
End;

// A Var parameter, on each side
Procedure VarForm(Var v : String);
Begin
    If Not (v = s) Then Error(400);
    If Not (s = v) Then Error(401);
    If Not (v < 'abd') Then Error(402);
    If Not ('abd' > v) Then Error(403);
End;

// A value parameter, on each side
Procedure ValForm(v : String);
Begin
    If v <> s Then Error(410);
    If s <> v Then Error(411);
    If Not (v >= 'abc') Then Error(412);
    If Not ('abb' <= v) Then Error(413);
End;

Function Make(x : String) : String;
Begin
    Make := x;
End;

// The function's own result, in its body
Function Own(n : Integer) : String;
Begin
    Own := 'own';
    If Own <> 'own' Then Error(420);
    If Not ('own' = Own) Then Error(421);
    If Not (Own < 'owo') Then Error(422);
End;

Procedure TestForms;
Begin
    s := 'abc';

    // A field
    r.s := 'abc';
    If Not (r.s = s) Then Error(500);
    If s <> r.s Then Error(501);
    If Not (r.s < 'abd') Then Error(502);

    // An element
    e[2] := 'abd';
    If Not (e[2] > s) Then Error(510);
    If Not (s < e[2]) Then Error(511);
    If e[2] <> 'abd' Then Error(512);

    // Parameters
    VarForm(s);
    ValForm(s);

    // A pointer
    ps := @s;
    If ps^ <> 'abc' Then Error(520);
    If Not ('abc' = ps^) Then Error(521);
    If Not (ps^ < e[2]) Then Error(522);

    // A constant
    If K <> s Then Error(530);
    If Not (s = K) Then Error(531);

    // Literals, on each side and both
    If Not (s = 'abc') Then Error(540);
    If Not ('abc' = s) Then Error(541);
    If Not ('abb' < s) Then Error(542);
    If Not (s >= 'abc') Then Error(543);
    If Not ('abc' < 'abd') Then Error(544);
    If 'abc' = 'abd' Then Error(545);

    // Concatenations, on each side and both
    If Not (s + 'd' = 'abcd') Then Error(550);
    If Not ('abcd' = s + 'd') Then Error(551);
    If Not (s + 'd' > s) Then Error(552);
    If Not (s < s + 'd') Then Error(553);
    If Not (s + 'x' < s + 'y') Then Error(554);
    If s + 'x' = s + 'y' Then Error(555);

    // Function results, on each side and both
    If Not (Make('abc') = s) Then Error(560);
    If Not (s = Make('abc')) Then Error(561);
    If Not (Make('a') < Make('b')) Then Error(562);
    If Not (Make(s) + 'd' > Make(s)) Then Error(563);
    If Own(1) <> 'own' Then Error(564);

    // Arrays of Char, as strings of their lengths
    If Not (a3 = s) Then Error(570);
    If Not (s = a3) Then Error(571);
    If Not (a3 = 'abc') Then Error(572);
    If Not (a3 < a4) Then Error(573);       // Two lengths
    If Not (a4 > a3) Then Error(574);
    If Not (b3 > a3) Then Error(575);       // Other bounds
    If Not (a3 < b3) Then Error(576);
    If a3 = b3 Then Error(577);
    If Not ('abcd' = a4) Then Error(578);
    If Not (a4 = s + 'd') Then Error(579);
    r.a[1] := 'a';
    r.a[2] := 'b';
    r.a[3] := 'c';
    If Not (r.a = a3) Then Error(580);      // A field
    If Not (r.a = s) Then Error(581);
    If Not (s <= r.a) Then Error(582);
    If r.a <> 'abc' Then Error(583);

    // A Char, as a one-character string
    c := 'a';
    d := 'b';
    t := 'a';
    If Not (c < s) Then Error(590);         // A prefix
    If Not (s > c) Then Error(591);
    If Not (c = t) Then Error(592);
    If Not (t = c) Then Error(593);
    If Not (d > s) Then Error(594);
    If Not (s < d) Then Error(595);
    If Not (c > '') Then Error(596);
    If Not ('' < c) Then Error(597);
    If Not (c < a3) Then Error(598);
    If Not (d > s + 'd') Then Error(599);

    // A Char literal
    If Not ('a' < s) Then Error(600);
    If Not (s > 'a') Then Error(601);
    If Not (t = 'a') Then Error(602);
    If Not ('a' = t) Then Error(603);
    If Not ('b' > s) Then Error(604);
    If Not (s < 'b') Then Error(605);
    If 'a' = 'A' + '' Then Error(606);

    // A string's character against a string
    If Not (s[1] = t) Then Error(610);
    If Not (t = s[1]) Then Error(611);
    If Not (s[2] > t) Then Error(612);
    If Not (s[3] > s) Then Error(613);
End;

// A Char against a Char still compares as an ordinal
Procedure TestChars;
Begin
    s := 'abc';
    t := 'cba';
    c := 'a';
    d := 'b';
    If Not (s[1] = 'a') Then Error(700);
    If Not (s[1] < s[2]) Then Error(701);
    If Not (s[3] > s[1]) Then Error(702);
    If s[1] <> t[3] Then Error(703);
    If Not (s[1] < t[1]) Then Error(704);
    If Not (c < d) Then Error(705);
    If Not (c = 'a') Then Error(706);
    If Not ('b' = d) Then Error(707);
    If Not (Chr(200) > c) Then Error(708);
    If Not ('a' < 'A') Then Error(709);
    l := 'm';
    If Not (l > c) Then Error(710);         // A Char subrange
    If Not (c < l) Then Error(711);
    If l <> 'm' Then Error(712);
    If Not (a3[2] = d) Then Error(713);
    If Not (a3[1] < a3[2]) Then Error(714);
End;

// The results in each kind of Boolean context
Procedure TestContexts;
Begin
    s := 'abc';
    t := 'a';

    // While
    u := '';
    n := 0;
    While u < 'xxxx' Do Begin
        u := u + 'x';
        n := n + 1;
    End;
    If n <> 4 Then Error(800);

    // Repeat
    u := '';
    n := 0;
    Repeat
        u := u + 'y';
        n := n + 1;
    Until u = 'yyy';
    If n <> 3 Then Error(801);

    // Assigned to a Boolean
    b := s < 'abd';
    If Not b Then Error(802);
    b := s + 'x' = 'abc';
    If b Then Error(803);

    // And, Or and Not
    If Not ((s = 'abc') And (t = 'a')) Then Error(804);
    If (s = 'abc') And (t = 'b') Then Error(805);
    If Not ((s = 'x') Or (t < 'b')) Then Error(806);
    If (s = 'x') Or (t = 'b') Then Error(807);
    If Not (s <> 'x') Then Error(808);
    b := Not (s > t) Or (s = t);
    If b Then Error(809);

    // A Boolean argument
    Expect(810, s < 'abd', true);
    Expect(811, s = 'abd', false);
    Expect(812, Make(s) >= a3, true);
End;

// An array of 255 Chars, the longest that is a string, compared and
// concatenated
Procedure TestBig;
Begin
    For i := 1 To 255 Do big[i] := 'x';
    If big <> long1 Then Error(900);
    If Not (long1 = big) Then Error(901);
    If Not (big > long3) Then Error(902);
    If Not (big < long2) Then Error(903);
    If Length(big + '') <> 255 Then Error(904);
    If big + '' <> long1 Then Error(905);
    big[255] := 'y';
    If big <> long2 Then Error(906);
    If Not (big > long1) Then Error(907);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running string comparison tests');

    long1 := '';
    long3 := '';
    For i := 1 To 254 Do long3 := long3 + 'x';
    long1 := long3 + 'x';
    long2 := long3 + 'y';
    If Length(long1) <> 255 Then Error(1);
    If Length(long2) <> 255 Then Error(2);
    s := 'abc';
    t := 'abd';

    TestPairs;
    TestForms;
    TestChars;
    TestContexts;
    TestBig;

    If anyErrors Then ReportFailure;
End.
