(*
    Error Test 20 - expect errMissingUNTIL on line 11
    Repeat ended by End instead of Until
*)

Program Test;
Var x : Integer;
Begin
    Repeat
        x := 1;
    End;
End.
