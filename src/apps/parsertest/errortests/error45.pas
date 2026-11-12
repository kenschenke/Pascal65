(*
    Error Test 45 - expect errMissingEND on line 12
    Record type without End
*)

Program Test;

Type
    r = Record
        a : Integer;

Var
    x : Integer;

Begin
End.
