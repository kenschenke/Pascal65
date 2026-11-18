// A unit for unitinit.pas, after UInitA in the program's Uses. Its
// variables come after UInitA's in the program's frame.

Unit UInitB;

Interface

Var
    bWords : Array[1..2] Of String = ('one', 'two');
    bChar : Char = 'q';
    bCount : Integer = -3;

Function BTotal : Integer;

Implementation

Var
    privTotal : Integer = 40;

Function BTotal : Integer;
Begin
    BTotal := privTotal + bCount;
End;

End.
