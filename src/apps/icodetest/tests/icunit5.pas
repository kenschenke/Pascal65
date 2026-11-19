// A unit for icode test 45. It uses IcLib, a library the program doesn't.

Unit IcUnit5;

Interface

Uses IcLib;

Procedure Count(n : Integer);

Implementation

Procedure Count(n : Integer);
Begin
  LibCount := n;
  LibProc(n);
End;

End.
