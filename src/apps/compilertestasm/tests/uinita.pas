// A unit for unitinit.pas. Its variables are set up by its init block,
// which the program's startup calls: interface and implementation
// variables of each kind, with and without initial values.

Unit UInitA;

Interface

Type
    APoint = Record
        x, y : Integer;
    End;

Var
    aCount : Integer = 7;
    aName : String = 'alpha';
    aList : Array[1..4] Of Integer = (11, 22, 33, 44);
    aPt : APoint;
    aFlag : Boolean = true;
    aReal : Real = 2.5;
    aEmpty : String;

Function APrivNum : Integer;
Function APrivStr : String;
Function APrivChar(i : Integer) : Char;
Procedure ASetPriv(n : Integer);

Implementation

Var
    privNum : Integer = 1000;
    privStr : String = 'secret';
    privChars : Array[0..2] Of Char = ('x', 'y', 'z');

Function APrivNum : Integer;
Begin
    APrivNum := privNum;
End;

Function APrivStr : String;
Begin
    APrivStr := privStr;
End;

Function APrivChar(i : Integer) : Char;
Begin
    APrivChar := privChars[i];
End;

Procedure ASetPriv(n : Integer);
Begin
    privNum := n;
    aPt.x := n;
    aPt.y := n + 1;
End;

End.
