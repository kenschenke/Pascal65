// A unit for unituses.pas, which uses it and UUseB, which uses it too.
// It is one unit: one init block and one set of slots.

Unit UUseA;

Interface

Var
    aCount : Integer = 7;
    aName : String = 'alpha';

Procedure ABump(n : Integer);
Function ATotal : Integer;

Implementation

Var
    aCalls : Integer = 100;

Procedure ABump(n : Integer);
Begin
    aCount := aCount + n;
    aCalls := aCalls + 1;
End;

Function ATotal : Integer;
Begin
    ATotal := aCount + aCalls;
End;

End.
