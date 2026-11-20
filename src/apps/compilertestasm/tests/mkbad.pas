// Error test (compiletests.s): MkErr has an error, which make finds
// compiling it on its own. Its temporary files must be erased.

Program MkBad;

Uses MkErr;

Begin
    MkErrProc;
End.
