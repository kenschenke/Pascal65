// Make tests (compiletests.s): MkB uses MkA in its interface, so a change
// to MkA's interface recompiles it. MkC uses MkB.

Unit MkB;

Interface

Uses MkA;

Function MkBVal : Integer;

Implementation

Function MkBVal : Integer;
Begin
    MkBVal := MkAVal + 10;
End;

End.
