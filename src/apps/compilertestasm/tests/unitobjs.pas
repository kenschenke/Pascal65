Program UnitObjs;

// Each module is linked from its own object file (plans/objcode.md
// Phase 3). UObjS is used by two units, UObjL and UObjR, and by the
// program. Each module's string literals and data blocks are its own, and
// a module reaches another's routines and variables through its exports.

Uses UObjL, UObjR, UObjS;

Var
    anyErrors : Boolean;
    errList : String;

Procedure Error(num : Integer);
Begin
    Writeln('UnitObjs (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'unitobjs:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running unit object tests');

    total := 0;
    LPoke;
    RPoke;
    If arr[1] <> 11 Then Error(1);
    If arr[2] <> 22 Then Error(2);
    If pr.a <> 5 Then Error(3);
    If pr.b <> 6 Then Error(4);
    If total <> 3 Then Error(5);
    If RPeek <> 16 Then Error(6);
    If CompareStr(SName, 'shared') <> 0 Then Error(7);
    If CompareStr(LName, 'left shared') <> 0 Then Error(8);
    If CompareStr(RName, 'right shared') <> 0 Then Error(9);
    arr[3] := 33;
    SAdd(10);
    If total <> 13 Then Error(10);
    If arr[3] + arr[1] <> 44 Then Error(11);

    If anyErrors Then ReportFailure;
End.
