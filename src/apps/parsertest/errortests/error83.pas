(*
    Error Test 83 - expect errMissingEND on line 11
    Case without End
*)

Program Test;
Var i : Integer;
Begin
    Case i Of
        1: i := 2;
    Begin
    End;
End.
