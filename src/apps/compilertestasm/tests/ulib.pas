// A unit for unitlib.pas. It uses DemoLib, a library the program doesn't
// name: the unit calls its routines and reads and writes its variables.

Unit ULib;

Interface

Uses DemoLib;

Var
    uCalls : Integer = 0;

Function UArea(w, h : Integer) : Integer;
Procedure USetPublic(n : Integer);
Function UGetPublic : Integer;
Procedure UDoublePublic;

Implementation

Function UArea(w, h : Integer) : Integer;
Begin
    uCalls := uCalls + 1;
    UArea := DemoArea(w, h);
End;

Procedure USetPublic(n : Integer);
Begin
    PublicInt := n;
End;

Function UGetPublic : Integer;
Begin
    UGetPublic := PublicInt;
End;

Procedure UDoublePublic;
Begin
    DoublePublicInt;
End;

End.
