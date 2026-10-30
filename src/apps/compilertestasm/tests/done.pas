Program Done;

// Last program in each chain of compiler tests. It is only reached when every
// earlier test in the chain ran to completion. A test that finds a problem
// adds its name and the error numbers it logged to a file named "testfailed"
// (or "testfaila" and "testfailb" for the two file tests). This program
// prints those files, then a result line that the Makefile test target
// looks for.

Var
    f : Text;
    s : String;
    anyFailed : Boolean;

Begin
    anyFailed := false;
    Write(Chr(147));

    Assign(f, 'testfailed');
    Reset(f);
    If IOResult = 0 Then Begin
        Readln(f, s);
        Close(f);
        Writeln(s);
        anyFailed := true;
    End;

    Assign(f, 'testfaila');
    Reset(f);
    If IOResult = 0 Then Begin
        Readln(f, s);
        Close(f);
        Writeln(s);
        anyFailed := true;
    End;

    Assign(f, 'testfailb');
    Reset(f);
    If IOResult = 0 Then Begin
        Readln(f, s);
        Close(f);
        Writeln(s);
        anyFailed := true;
    End;

    If anyFailed Then
        Writeln('RESULT: FAIL')
    Else
        Writeln('RESULT: PASS');
End.
