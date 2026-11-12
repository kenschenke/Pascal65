(*
    Error Test 19 - expect errMissingSemicolon on line 10
    Missing semicolon before If
*)

Program Test;
Var x : Integer;
Begin
    x := 1
    If x = 1 Then x := 2;
End.
