(*
    Error Test 81 - expect errMissingTHEN on line 10
    If without Then
*)

Program Test;
Var i : Integer;
Begin
    If i = 1
        i := 2;
End.
