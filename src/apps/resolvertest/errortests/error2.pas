// Resolver Error Test 2
// A named dynamic array type as a record field

Program Test;

Type
    TDyn = Array Of Integer;
    TRec = Record
        i : Integer;
        s : String;
        d : TDyn;                           // Error
    End;

Begin
End.
