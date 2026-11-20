Program MkCycle;

// An error test: CycA uses CycB, which uses CycA, so the make walk
// reports errCircularUnitReference.

Uses CycA;

Begin
End.
