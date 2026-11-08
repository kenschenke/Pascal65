(*
    Error Test 24
    Repeating a runtime directive is harmless, but the other one
    after it conflicts
*)

Program Test;
(* $DynamicRuntime *)
(* $DynamicRuntime *)
(* $StaticRuntime *)
Begin
End.
