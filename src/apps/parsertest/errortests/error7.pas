(*
    Error Test 7
    Invalid constant parsing case branch
*)

Program Test;

Begin
    Case i Of
        one, two: Write('Hello');
        three, -four: Write('World');
    End;
End.
