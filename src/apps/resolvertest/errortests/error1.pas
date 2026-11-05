// Resolver Error Test 1
// A named dynamic array type as the element of an array. Other uses of the
// named types are fine, and a variable of the bad type is not reported again.

Program Test;

Type
    TDyn = Array Of Integer;
    TStatic = Array[1..3] Of Integer;
    TOk = Array[1..3] Of TStatic;
    TDyn2 = TDyn;
    TArr = Array[1..3] Of TDyn;             // Error
    TRec = Record
        i : Integer;
        s : TStatic;
    End;

Var
    d : TDyn;
    d2 : TDyn2;
    ok : TOk;
    t : TArr;
    p : Array Of TRec;

Begin
End.
