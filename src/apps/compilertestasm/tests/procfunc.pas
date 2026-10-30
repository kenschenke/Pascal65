(* Procedure / Function Tests *)

Program ProcFunc;
Type
    Months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);

Var
    anyErrors : Boolean;
    errList : String;
    i : Integer;
    c : Char;
    m : Months;

Procedure Error(num : Integer);
Begin
    Writeln('ProcFunc (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure Proc(num : Integer; ch : Char; mon : Months);
Begin
    If num <> 1234 Then Error(1);
    If ch <> 'x' Then Error(2);
    If mon <> Apr Then Error(3);
End;

Function IntSucc(num : Integer) : Integer;
Begin
    IntSucc := num + 1;
End;

Function CharSucc(ch : Char) : Char;
Begin
    CharSucc := Succ(ch);
End;

Function EnumSucc(mon : Months) : Months;
Begin
    EnumSucc := Succ(mon);
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
    If Length(acc) < 150 Then acc := acc + 'procfunc:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running procedure and function tests');

    Proc(1234, 'x', Apr);
    i := 1234;
    c := 'x';
    m := Apr;
    Proc(i, c, m);

    If IntSucc(1255) <> 1256 Then Error(4);
    If IntSucc(i) <> 1235 Then Error(5);
    If CharSucc('m') <> 'n' Then Error(6);
    If CharSucc(c) <> 'y' Then Error(7);
    If EnumSucc(May) <> Jun Then Error(8);
    If EnumSucc(m) <> May Then Error(9);

    If anyErrors Then ReportFailure;
End.
