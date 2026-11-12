(*
    Error Test 106 - expect errUnexpectedToken on line 9
    A keyword in an array literal, then a comma
*)

Program Test;

Var
    a : Array[1..3] Of Integer = (1, 2 If, 3);

Begin
End.
