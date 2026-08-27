Unit Unit1;

Interface

Type
    Colors = (Red, Green, Blue);
    UnitRec = Record
        i, j : Integer;
    End;
    UnitArray = Array[1..5] Of Integer;

Var
    Shared : Integer;

Procedure PublicProc(i : Integer);
Function PublicFunc1(i, j : Integer) : Integer;
Function PublicColor(c : Colors) : Integer;
Procedure PublicRec(Var r : UnitRec);
Procedure PublicArray(Var a : UnitArray);
Function TestSystemOdd(i : Integer): Boolean;

Implementation

Var
    Private : Integer;

Procedure PublicProc(i : Integer);
Begin
    Shared := i * 3;
End;

Function PublicFunc1(i, j : Integer) : Integer;
Var
    Local : Integer;
Begin
    Local := 15;
    i := Local * 5;
    j := i + 10;
    Private := j + 3;
    PublicFunc1 := Private * 2;
End;

Function PublicColor(c : Colors) : Integer;
Begin
    PublicColor := Ord(c);
End;

Procedure PublicRec(Var r : UnitRec);
Begin
    r.i := r.i * 2;
    r.j := r.j + 5;
End;

Procedure PublicArray(Var a : UnitArray);
Var
    i : Integer;
Begin
    For i := 1 To 5 Do a[i] := a[i] * 2;
End;

Function TestSystemOdd(i : Integer) : Boolean;
Begin
    TestSystemOdd := Odd(i);
End;

End.
