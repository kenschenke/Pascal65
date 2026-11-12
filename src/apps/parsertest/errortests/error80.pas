(*
    Error Test 80 - expect errMissingDO on line 10
    While without Do
*)

Program Test;
Var i : Integer;
Begin
    While i < 5
        i := i + 1;
End.
