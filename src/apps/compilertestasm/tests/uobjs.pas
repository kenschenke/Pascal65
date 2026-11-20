// A unit for unitobjs.pas, used by UObjL, UObjR and the program. Each
// unit is linked from its own object file (plans/objcode.md Phase 3), so
// its string literals and the blocks of its record and array are in its
// own module, which the others reach through its exports.

Unit UObjS;

Interface

Type
    Pair = Record
        a, b : Integer;
    End;

Var
    pr : Pair;
    arr : Array[1..4] Of Integer;
    total : Integer;

Procedure SAdd(n : Integer);
Function SName : String;

Implementation

Procedure SAdd(n : Integer);
Begin
    total := total + n;
End;

Function SName : String;
Begin
    SName := 'shared';
End;

End.
