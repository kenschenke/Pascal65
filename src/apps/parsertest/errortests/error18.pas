(*
    Error Test 18 - expect errUnexpectedToken on line 10
    Else after a semicolon
*)

Program Test;
Var x : Integer;
Begin
    If x = 1 Then x := 2;
    Else x := 3;
End.
