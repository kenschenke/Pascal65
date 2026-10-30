(* If-Then Tests *)

Program IfThen;
Var
    anyErrors : Boolean;
    errList : String;
    i, j, k : Integer;
    p : ^Integer;

Procedure Error(num : Integer);
Begin
    Writeln('IfThen (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'ifthen:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';
    i := 528;
    j := 1036;

    Writeln('Running if then tests');

    If i > 528 Then Error(1);
    If i > j Then Error(2);
    If (i > 529) Or (j < 1036) Then Error(3);
    If (i > 526) And (j < 1034) Then Error(4);
    If i > 522 Then k := 1 Else Error(5);
    If i >= 528 Then k := 1 Else Error(6);
    If j <= 1036 Then k := 1 Else Error(7);
    If Not (i > 526) Then Error(8);
    If i <> 528 Then Error(9);
    If Not (i > 526) Or (j > 1042) Then Error(10);

    p := @i;
    If p^ > 528 Then Error(11);

    If anyErrors Then ReportFailure;
End.
