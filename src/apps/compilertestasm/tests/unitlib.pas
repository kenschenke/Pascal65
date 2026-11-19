Program UnitLib;

// A library that only a unit uses. ULib uses DemoLib and the program
// doesn't. The libraries come from the units list, so DemoLib is linked,
// with its init and cleanup and its jump table, and the resolver puts it
// before ULib. It once came only from the program's own Uses, so DemoLib
// wasn't linked and the program didn't link.

Uses ULib;

Var
    anyErrors : Boolean;
    errList : String;
    before : Integer = 1234;

Procedure Error(num : Integer);
Begin
    Writeln('UnitLib (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'unitlib:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running unit library tests');

    If UArea(5, 6) <> 30 Then Error(1);
    If uCalls <> 1 Then Error(2);
    USetPublic(21);
    If UGetPublic <> 21 Then Error(3);
    UDoublePublic;
    If UGetPublic <> 42 Then Error(4);
    If before <> 1234 Then Error(5);

    If anyErrors Then ReportFailure;
End.
