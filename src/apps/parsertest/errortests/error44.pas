(*
    Error Test 44 - expect errMissingOF on line 12
    Array type without Of
*)

Program Test;

Type
    t = Integer;

Var
    a : Array[1..5] t;

Begin
End.
