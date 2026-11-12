(*
    Error Test 89 - expect errUnexpectedToken on line 10
    ExpectError directive with no handler for it
*)

Program Test;
Var i : Integer;
Begin
    i := 1;
    (* $ExpectError 35 *)
End.
