(*
    Error Test 108 - expect errInvalidExpression on line 10
    Case label of only a minus
*)

Program Test;
Var i : Integer;
Begin
    Case i Of
        -: i := 1;
    End;
End.
