Program WdSearch;

// Set 4 runs with a work disk on unit 9 (plans/workdisks.md). WdUnit's
// source is on both disks: the work disk's says 9 and the system disk's
// 8. A unit is found on the work disk first, so the program must get 9.
// The system disk's copy has a routine the work disk's doesn't, so it
// can't be used by mistake either.

Uses WdUnit;

Var
    anyErrors : Boolean;
    errList : String;

Procedure Error(num : Integer);
Begin
    Writeln('WdSearch (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'wdsearch:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running work disk search tests');

    If WdWhere <> 9 Then Error(1);
    If CompareStr(wdName, 'work') <> 0 Then Error(2);

    If anyErrors Then ReportFailure;
End.
