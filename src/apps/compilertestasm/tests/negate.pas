Program NegateTest;

// Unary minus of things other than number literals: variables of each
// numeric type, expressions, function calls, subscripts, casts and
// constants, and negative real literals. An unsigned operand is negated
// as the signed type that holds the result: Byte as Integer, Word and
// Cardinal as LongInt.

Const
    K = 12;

Var
    anyErrors : Boolean;
    errList : String;
    b : Byte;
    s : ShortInt;
    w : Word;
    i : Integer;
    c : Cardinal;
    l : LongInt;
    r : Real;
    rinit : Real = -1.5;
    a : Array[1..3] Of Integer;

Function Five : Integer;
Begin
    Five := 5;
End;

Function Twice(n : Integer) : Integer;
Begin
    Twice := n * 2;
End;

Procedure Error(num : Integer);
Begin
    Writeln('Negate (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure TestSigned;
Begin
    s := 100;
    s := -s;
    If s <> -100 Then Error(1);
    i := 1234;
    i := -i;
    If i <> -1234 Then Error(2);
    i := -i;
    If i <> 1234 Then Error(3);
    l := 123456;
    l := -l;
    If l <> -123456 Then Error(4);
    i := 0;
    i := -i;
    If i <> 0 Then Error(5);
    s := -5;
    s := -s;
    If s <> 5 Then Error(6);
End;

Procedure TestUnsigned;
Begin
    b := 200;
    i := -b;
    If i <> -200 Then Error(10);
    w := 40000;
    l := -w;
    If l <> -40000 Then Error(11);
    c := 100000;
    l := -c;
    If l <> -100000 Then Error(12);
    b := 5;
    i := 10 + -b;
    If i <> 5 Then Error(13);
End;

Procedure TestExpressions;
Begin
    i := 7;
    i := -(i + 3);
    If i <> -10 Then Error(20);
    i := -Five;
    If i <> -5 Then Error(21);
    i := -Twice(4);
    If i <> -8 Then Error(22);
    a[2] := 9;
    i := -a[2];
    If i <> -9 Then Error(23);
    i := 3;
    i := -i * -i;
    If i <> 9 Then Error(24);
    i := 4;
    i := i - -i;
    If i <> 8 Then Error(25);
    i := 6;
    If -i >= 0 Then Error(26);
    i := -(5);
    If i <> -5 Then Error(27);
    i := -(-5);
    If i <> 5 Then Error(28);
    w := 300;
    i := -Integer(w);
    If i <> -300 Then Error(29);
    i := -K;
    If i <> -12 Then Error(30);
End;

Procedure TestReal;
Begin
    r := 2.5;
    r := -r;
    If r > -2.4 Then Error(40);
    If r < -2.6 Then Error(41);
    i := 3;
    r := -i;
    If r > -2.9 Then Error(42);
    If r < -3.1 Then Error(43);
    // A negative real literal
    If rinit > -1.4 Then Error(44);
    If rinit < -1.6 Then Error(45);
    r := -0.5;
    If r > -0.4 Then Error(46);
    If r < -0.6 Then Error(47);
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
    If Length(acc) < 150 Then acc := acc + 'negate:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running negation tests');

    TestSigned;
    TestUnsigned;
    TestExpressions;
    TestReal;

    If anyErrors Then ReportFailure;
End.
