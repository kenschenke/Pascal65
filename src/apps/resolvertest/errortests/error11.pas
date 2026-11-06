// Resolver Error Test 11
// A record field defined twice

Program Test;

Type
    TRec = Record
        a : Integer;
        b : Integer;
        a : Char;                           // Error
    End;

Begin
End.
