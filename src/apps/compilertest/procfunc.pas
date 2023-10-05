(* Procedure / Function Tests *)

Program ProcFunc;
Type
    Months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);

Var
    anyErrors : Boolean;
    i : Integer;
    c : Char;
    m : Months;

Procedure Error(num : Integer);
Begin
    Writeln('ProcFunc (', num, ')');
    anyErrors := true;
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

Begin
    anyErrors := false;

    Writeln('Running');

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

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
