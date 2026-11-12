// Parser directive test: rundirtest.s checks the stack size, the
// runtime mode and what the $Expect handlers are called with.
Program Dirs;
(* $StackSize 1000 *)
(* $StaticRuntime *)

Var i : Integer;

Begin
    i := 1; (* $ExpectWarn 66 *)
    (* $ExpectError 35 *)
    i := 2;
End.
