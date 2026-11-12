(*
    Error Test 94 - expect errMissingRightBracket on line 10
    Subscript without ]
*)

Program Test;
Var i : Integer;
    a : Array[1..5] Of Integer;
Begin
    i := a[1;
End.
