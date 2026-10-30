Program Done;

// Last program in each chain of compiler tests. It is only reached when every
// earlier test in the chain ran to completion. A test that finds a problem
// adds its name and the error numbers it logged to a file named "testfailed".
// This program prints that file, then a result line that the Makefile test
// target looks for.

Var
    f : Text;
    s : String;

Begin
    Write(Chr(147));
    Assign(f, 'testfailed');
    Reset(f);
    If IOResult = 0 Then Begin
        Readln(f, s);
        Close(f);
        Writeln(s);
        Writeln('RESULT: FAIL');
    End Else
        Writeln('RESULT: PASS');
End.
