(*
    Error Test 107 - expect errUnexpectedToken on line 9
    A keyword in an array literal, then an element
*)

Program Test;

Var
    a : Array[1..3] Of Integer = (1, 2 If 3);

Begin
End.
