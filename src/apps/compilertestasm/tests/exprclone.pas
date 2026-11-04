Program ExprCloneTest;

// When several variables are declared with one type, every variable after
// the first gets a clone of the type, including the expressions for the
// array limits. A negative limit has to stay negative in the clone.

Var
    anyErrors : Boolean;
    errList : String;
    a, b, c : Array[-2..2] Of Integer;
    d, e : Array[-5..-1] Of Integer;
    i : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('ExprClone (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure TestLowerLimit;
Begin
    a[-2] := 11;
    b[-2] := 22;
    c[-2] := 33;
    If a[-2] <> 11 Then Error(100);
    If b[-2] <> 22 Then Error(101);
    If c[-2] <> 33 Then Error(102);
End;

Procedure TestWholeRange;
Begin
    For i := -2 To 2 Do Begin
        a[i] := i;
        b[i] := i * 2;
        c[i] := i * 3;
    End;
    For i := -2 To 2 Do Begin
        If a[i] <> i Then Error(200);
        If b[i] <> i * 2 Then Error(201);
        If c[i] <> i * 3 Then Error(202);
    End;
End;

Procedure TestNegativeLimits;
Begin
    d[-5] := 1;
    e[-5] := 2;
    d[-1] := 3;
    e[-1] := 4;
    e[-3] := 5;
    If d[-5] <> 1 Then Error(300);
    If e[-5] <> 2 Then Error(301);
    If d[-1] <> 3 Then Error(302);
    If e[-1] <> 4 Then Error(303);
    If e[-3] <> 5 Then Error(304);
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
    If Length(acc) < 150 Then acc := acc + 'exprclone:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running expression clone tests');

    TestLowerLimit;
    TestWholeRange;
    TestNegativeLimits;

    If anyErrors Then ReportFailure;
End.
