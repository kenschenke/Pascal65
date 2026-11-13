// A unit with code for icode test 36.

Unit IcUnit;

Interface

Var
  Total : Integer;

Procedure AddTo(n : Integer);

Implementation

Procedure AddTo(n : Integer);
Begin
  Total := Total + n;
End;

End.
