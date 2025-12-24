(*
    Error Test 6
    Missing constant parsing case branch
*)

Program Test;

Begin
    Case i Of
        1, 2: Write('Hello');
        3, : Write('World');
    End;
End.
