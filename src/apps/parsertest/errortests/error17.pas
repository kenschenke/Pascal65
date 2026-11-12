(*
    Error Test 17 - expect errMissingEND on line 9
    Stray token in a statement list (used to hang the parser)
*)

Program Test;
Var x : Integer;
Begin
    x := 1 );
    x := 2;
End.
