(*
    Error Test 87 - expect errInvalidNumber on line 9
    ExpectWarn directive without a number
*)

Program Test;
Var i : Integer;
Begin
    (* $ExpectWarn abc *)
    i := 1;
End.
