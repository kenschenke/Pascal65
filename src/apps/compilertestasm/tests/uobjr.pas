// A unit for unitobjs.pas. It uses UObjS in its implementation, reads
// and writes its record and array and calls its routine through a
// pointer.

Unit UObjR;

Interface

Procedure RPoke;
Function RPeek : Integer;
Function RName : String;

Implementation

Uses UObjS;

Type
    AddProc = Procedure(n : Integer);

Var
    ap : AddProc;

Procedure RPoke;
Begin
    arr[2] := 22;
    pr.b := 6;
    ap := @SAdd;
    ap(2);
End;

Function RPeek : Integer;
Begin
    RPeek := arr[1] + pr.a;
End;

Function RName : String;
Begin
    RName := 'right ' + SName;
End;

End.
