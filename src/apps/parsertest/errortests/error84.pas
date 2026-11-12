(*
    Error Test 84 - expect errMissingColon on line 10
    Case branch without a colon
*)

Program Test;
Var i : Integer;
Begin
    Case i Of
        1 i := 2;
    End;
End.
