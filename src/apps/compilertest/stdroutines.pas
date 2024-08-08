(* Standard Routine Tests *)

Program StdRoutines;
Type
    Months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Decem);

Var
    anyErrors : Boolean;
    c : Char;
    i : Integer;
    m : Months;
    r : Real;
    b : Byte;
    s : ShortInt;
    w : Word;
    l : LongInt;
    d : Cardinal;

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

    b := 192;
    Inc(b);
    If b <> 193 Then Error(31);
    Inc(b, 4);
    If b <> 197 Then Error(32);
    b := 240;
    Dec(b);
    If b <> 239 Then Error(33);
    Dec(b, 8);
    If b <> 231 Then Error(34);

    s := -102;
    Inc(s);
    If s <> -101 Then Error(35);
    Inc(s, 7);
    If s <> -94 Then Error(36);
    s := -118;
    Dec(s);
    If s <> -119 Then Error(37);
    Dec(s, 3);
    If s <> -122 Then Error(38);

    w := 41135;
    Inc(w);
    If w <> 41136 Then Error(39);
    Inc(w, 5);
    If w <> 41141 Then Error(40);
    w := 38945;
    Dec(w);
    If w <> 38944 Then Error(41);
    Dec(w, 6);
    If w <> 38938 Then Error(42);

    i := -13245;
    Inc(i);
    If i <> -13244 Then Error(43);
    Inc(i, 10);
    If i <> -13234 Then Error(44);
    i := -24353;
    Dec(i);
    If i <> -24354 Then Error(45);
    Dec(i, 9);
    If i <> -24363 Then Error(46);

    d := 145434;
    Inc(d);
    If d <> 145435 Then Error(47);
    Inc(d, 11);
    If d <> 145446 Then Error(48);
    d := 234253;
    Dec(d);
    If d <> 234252 Then Error(49);
    Dec(d, 3);
    If d <> 234249 Then Error(50);

    l := -434245;
    Inc(l);
    If l <> -434244 Then Error(51);
    Inc(l, 2);
    If l <> -434242 Then Error(52);
    l := -142235;
    Dec(l);
    If l <> -142236 Then Error(53);
    Dec(l, 3);
    If l <> -142239 Then Error(54);

    w := 12345;
    b := 100;
    Inc(w, b);
    If w <> 12445 Then Error(55);
    w := 12345;
    i := 1000;
    Inc(w, i);
    If w <> 13345 Then Error(56);
    w := 12345;
    d := 2;
    Inc(w, d);
    If w <> 12347 Then Error(57);

    w := 12345;
    s := 4;
    Inc(w, s);
    If w <> 12349 Then Error(58);
    i := 12345;
    w := 10;
    Inc(i, w);
    If i <> 12355 Then Error(59);
    w := 12345;
    d := 3;
    Inc(w, d);
    If w <> 12348 Then Error(60);

    i := 12345;
    Inc(i, -5);
    If i <> 12340 Then Error(61);
    Dec(i, -10);
    If i <> 12350 Then Error(62);

    m := Mar;
    Inc(m);
    If m <> Apr Then Error(63);
    Inc(m, 2);
    If m <> Jun Then Error(64);
    m := Nov;
    Dec(m);
    If m <> Oct Then Error(65);
    Dec(m, 2);
    If m <> Aug Then Error(66);

    c := 'd';
    Inc(c);
    If c <> 'e' Then Error(67);
    Inc(c, 2);
    If c <> 'g' Then Error(68);
    Dec(c);
    If c <> 'f' Then Error(69);
    Dec(c, 3);
    If c <> 'c' Then Error(70);

    If anyErrors Then Begin
        Write('Type any key to continue: ');
        c := GetKey;
    End;
End.
