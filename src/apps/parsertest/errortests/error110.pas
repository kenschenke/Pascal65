(*
    Error Test 110 - expect errMissingRightParen on line 17
    A field width in a call that isn't to Write, Writeln or WriteStr.
    The parser once read the flag that allows it from the wrong place on
    its stack, so every call took one.
*)

Program Test;

Procedure Show(n : Integer);
Begin
End;

Begin
    Writeln(1:2);
    Show(3);
    Show(4:5);
End.
