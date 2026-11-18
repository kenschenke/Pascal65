(* Test 42 - The header from the directives and the name
HDR PRG headername 1 3e8
BRA LBL xxxxx
LOC LBL xxxxx
EOM IBU 0
*)

// The icode file starts with a header (icode.inc): the kind, the runtime
// mode and stack size the parser found and the module's name.

Program HeaderName;

(* $StackSize 1000 *)
(* $StaticRuntime *)

Begin
End.
