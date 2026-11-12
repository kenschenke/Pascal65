(*
    Error Test 31 - expect errMissingEND on line 19
    A unit with a Begin block but no End after it
*)

Unit Test;

Interface

Procedure PublicProc;

Implementation

Procedure PublicProc;
Begin
End;

Begin
End.
