(*
    Error Test 15 - expect errDynArrayInRecord on line 11
    Dynamic array as a record field
*)

Program Test;

Type
    Rec = Record
        i : Integer;
        arr : Array Of Integer;
    End;

Begin
End.
