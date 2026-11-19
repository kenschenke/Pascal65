// A unit with code for test 2

Unit TpuUnit;

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
