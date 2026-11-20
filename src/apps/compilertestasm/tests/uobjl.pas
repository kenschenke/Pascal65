// A unit for unitobjs.pas. It uses UObjS in its interface, calls its
// routines and writes its record and array.

Unit UObjL;

Interface

Uses UObjS;

Procedure LPoke;
Function LName : String;

Implementation

Procedure LPoke;
Begin
    arr[1] := 11;
    pr.a := 5;
    SAdd(1);
End;

Function LName : String;
Begin
    LName := 'left ' + SName;
End;

End.
