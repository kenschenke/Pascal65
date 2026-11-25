Program Done;

// Last program in each chain of compiler tests. A test that finds a problem
// adds its name and the error numbers it logged to a file named "testfailed".
// A test that ends with a runtime error still chains to the next program,
// so the runtime records the error at RTERR_RECORD (asm.inc, $1EFA): "ER"
// and the error's code. This program prints both, clears the record, then
// prints a result line that the Makefile test target looks for.

Var
    f : Text;
    s : String;
    failed : Boolean;

Begin
    Write(Chr(147));
    failed := false;
    If (Peek($1EFA) = 69) And (Peek($1EFB) = 82) Then Begin
        Writeln('a test ended with runtime error ', Peek($1EFC));
        Poke($1EFA, 0);
        failed := true;
    End;
    Assign(f, 'testfailed');
    Reset(f);
    If IOResult = 0 Then Begin
        Readln(f, s);
        Close(f);
        Writeln(s);
        failed := true;
    End;
    If failed Then Writeln('RESULT: FAIL') Else Writeln('RESULT: PASS');
End.
