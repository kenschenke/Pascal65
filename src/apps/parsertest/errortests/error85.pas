(*
    Error Test 85 - expect errMissingSemicolon on line 11
    Case branches without a semicolon between them
*)

Program Test;
Var i : Integer;
Begin
    Case i Of
        1: Writeln(1)
        2: Writeln(2);
    End;
End.
