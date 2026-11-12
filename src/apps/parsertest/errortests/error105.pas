(*
    Error Test 105 - expect errUnexpectedToken on line 10
    Array literal element without a comma before it
*)

Program Test;

Var
    i : Integer;
    a : Array[1..3] Of Integer = (1, 2 i);

Begin
End.
