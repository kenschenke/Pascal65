// A unit for unituses.pas. It uses UUseA, which the program uses too:
// its routines call UUseA's and read and write UUseA's variables.

Unit UUseB;

Interface

Uses UUseA;

Var
    bWord : String = 'beta';
    bCount : Integer = -3;

Procedure BBumpBoth(n : Integer);
Function BSeesA : Integer;

Implementation

Procedure BBumpBoth(n : Integer);
Begin
    ABump(n);
    bCount := bCount + n;
    aName := aName + '+';
End;

Function BSeesA : Integer;
Begin
    BSeesA := aCount;
End;

End.
