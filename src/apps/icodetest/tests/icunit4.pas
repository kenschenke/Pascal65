// A unit for icode test 44. It uses IcUnit, which the program uses too.

Unit IcUnit4;

Interface

Uses IcUnit;

Procedure Twice(n : Integer);

Implementation

Procedure Twice(n : Integer);
Begin
  AddTo(n);
  AddTo(n);
End;

End.
