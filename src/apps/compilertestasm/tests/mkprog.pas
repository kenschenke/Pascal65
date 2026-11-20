Program MkProg;

// Make tests (compiletests.s): each compile of this program must compile
// exactly the units the harness expects. The make walk reads the sources
// for their Uses clauses outside comments and strings, so the lines below
// mustn't make it walk CycA, which uses itself through CycB.
// Uses CycA;
(* Uses CycA; *)

Uses MkB, MkC;

Begin
    Writeln('Uses CycA;', MkBVal, MkCVal);
End.
