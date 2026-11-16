(* Runtime Error Exit Test *)

Program RtErrExit;

// Ends with a runtime error. rtdyntest.sh runs it and checks that it
// prints the error and returns to BASIC: the exit puts the KERNAL's IRQ
// handler back and runs the libraries' cleanup (Sound's here).

Uses Sound;

Var
    z : Integer;

Begin
    Writeln('Runtime error exit test');
    PlayNote(1, 4 * 12 + NoteA, 0);
    z := 0;
    z := 5 Div z;
    Writeln('Not reached');
End.
