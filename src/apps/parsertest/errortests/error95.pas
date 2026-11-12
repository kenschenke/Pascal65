(*
    Error Test 95 - expect errUnexpectedEndOfFile on line 9
    File ends in an array literal (used to hang)
*)

Program Test;

Var
    a : Array[1..3] Of Integer = (1, 2