Program StdRtnTest(input, output);

Type
    en = (one, two, three, four, five);

Var
    b : boolean;
    c : char;
    i, j : integer;
    e, e2 : en;
    r, r2 : real;
    s : array[1..20] of char;

Begin
    read(c, i, r);
    readln(s);

    write(b, c, i, r);
    write(false, 'a', 123);
    write(r:5);
    write(r:5:2);
    write(1.2345);
    write(1.2345:5);
    write(1.2345:5:2);
    writeln(s);

    b := eof;
    b := eoln;

    i := abs(j);
    i := abs(-5);
    r := abs(r2);
    r := abs(-1.2345);

    i := sqr(j);
    i := sqr(5);
    r := sqr(r2);
    r := sqr(5.11);

    i := pred(j);
    i := pred(10);
    e := pred(e2);
    e := pred(three);

    j := succ(j);
    j := succ(11);
    e := pred(e2);
    e := pred(four);

    c := chr(i);
    c := chr(65);

    b := odd(i);
    b := odd(11);

    i := ord(c);
    i := ord('c');
    i := ord(e);
    i := ord(three);

    i := round(r);
    i := round(1.234);
    i := trunc(r);
    i := trunc(2.345);
End.
