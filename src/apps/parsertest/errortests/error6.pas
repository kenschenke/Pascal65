(*
    Error Test 6 - expect errMissingConstant on line 11
    Missing constant parsing case branch
*)

Program Test;

Begin
    Case i Of
        1, 2: Write('Hello');
        3, : Write('World');
    End;
End.
