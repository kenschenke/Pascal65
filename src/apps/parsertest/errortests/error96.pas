(*
    Error Test 96 - expect errMissingRightParen on line 9
    Array literal ended by a semicolon (used to hang)
*)

Program Test;

Var
    a : Array[1..3] Of Integer = (1, 2;

Begin
End.
