(*
    Error Test 88 - expect errUnexpectedToken on line 9
    ExpectWarn directive with no handler for it
*)

Program Test;
Var i : Integer;
Begin
    (* $ExpectWarn 66 *)
    i := 1;
End.
