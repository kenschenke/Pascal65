// Make tests (compiletests.s): MkC uses MkB, whose interface doesn't
// change when MkA's does, so MkC isn't recompiled then.

Unit MkC;

Interface

Function MkCVal : Integer;

Implementation

Uses MkB;

Function MkCVal : Integer;
Begin
    MkCVal := MkBVal + 100;
End;

End.
