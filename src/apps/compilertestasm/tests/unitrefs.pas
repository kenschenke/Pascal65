Program UnitRefs;

// A unit's entries are named for the unit and their number in its
// interface (unit.N in icode), not by labels made from heap addresses.
// This calls the unit's routines directly and through a pointer, passes
// its record by value, sizes its dynamic array and reads its variables.

Uses URefs;

Type
    NumProc = Procedure(n : Integer);
    PtFunc = Function(p : Pt) : Integer;

Var
    anyErrors : Boolean;
    errList : String;
    np : NumProc;
    pf : PtFunc;
    i : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('UnitRefs (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'unitrefs:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Procedure TestCalls;
Begin
    calls := 0;
    Bump(5);
    If calls <> 5 Then Error(1);
    np := @Bump;
    np(7);
    If calls <> 12 Then Error(2);
End;

Procedure TestRecord;
Begin
    origin.x := 3;
    origin.y := 4;
    calls := 0;
    If PtSum(origin) <> 107 Then Error(3);
    If origin.x <> 3 Then Error(4);
    If calls <> 1 Then Error(5);
    pf := @PtSum;
    If pf(origin) <> 107 Then Error(6);
    If origin.x <> 3 Then Error(7);
End;

Procedure TestArray;
Begin
    If Length(vals) <> 0 Then Error(8);
    SetLength(vals, 4);
    If Length(vals) <> 4 Then Error(9);
    For i := 0 To 3 Do vals[i] := i * 3;
    SetLength(vals, 6);
    If Length(vals) <> 6 Then Error(10);
    If vals[3] <> 9 Then Error(11);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running unit reference tests');

    TestCalls;
    TestRecord;
    TestArray;

    If anyErrors Then ReportFailure;
End.
