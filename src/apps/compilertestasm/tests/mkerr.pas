// Make error test (mkbad.pas): an error in the implementation, found
// after the TPU's first part is written and type checked before icode.

Unit MkErr;

Interface

Procedure MkErrProc;

Implementation

Procedure MkErrProc;
Var
    i : Integer;
Begin
    i := 'x';
End;

End.
