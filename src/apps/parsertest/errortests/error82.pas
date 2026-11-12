(*
    Error Test 82 - expect errMissingOF on line 11
    Case without Of
*)

Program Test;
Const One = 1;
Var i : Integer;
Begin
    Case i
        One: i := 2;
    End;
End.
