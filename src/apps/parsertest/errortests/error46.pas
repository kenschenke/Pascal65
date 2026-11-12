(*
    Error Test 46 - expect errMissingSemicolon on line 11
    Record fields without a semicolon between them
*)

Program Test;

Type
    r = Record
        a : Integer
        b : Integer;
    End;

Begin
End.
