(*
    Error Test 77 - expect errMissingColonEqual on line 9
    For without :=
*)

Program Test;
Var i : Integer;
Begin
    For i 1 To 5 Do
        Writeln(i);
End.
