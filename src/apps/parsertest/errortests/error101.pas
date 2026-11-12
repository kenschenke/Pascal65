(*
    Error Test 101 - expect errUnexpectedEndOfFile on line 10
    File ends in a case statement
*)

Program Test;
Var i : Integer;
Begin
    Case i Of
        1: i := 2;