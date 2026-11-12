(*
    Error Test 76 - expect errMissingIdentifier on line 9
    For without a control variable
*)

Program Test;

Begin
    For := 1 To 5 Do
        Writeln(1);
End.
