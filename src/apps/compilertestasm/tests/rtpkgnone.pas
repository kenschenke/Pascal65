Program RtPkgNone;
(* $StaticRuntime *)

// Tests a program that uses none of the runtime packages: no file
// variable, no SetLength, no Sin, Cos or Tan. Code generation must link
// no package, so every package's jump table entries still point at the
// core's "package not linked" stubs.
//
// The stubs are 3 bytes apart, in package order (see rterror.s): the
// dynamic arrays stub, then files, then trig. Each check reads a jump
// table entry's target. A package that was linked would have its own
// addresses there instead.
//
// Without a file variable this test can't write the testfailed file, so
// a failure prints its number and ends the chain with a runtime error.

Const
    // The target of each jump table entry (RT_BASE $2028 + offset + 1)
    tgtSetLength = $2179;
    tgtFileOpen = $203B;
    tgtFileClose = $2050;
    tgtReadBytes = $2161;
    tgtSine = $2146;
    tgtCosine = $2149;
    tgtTangent = $214C;

Var
    zero : Integer;
    stub : Word;

Procedure Error(num : Integer);
Begin
    Writeln('RtPkgNone (', num, ') failed');
    // A runtime error ends the chain, which fails the tests
    zero := 0;
    zero := 1 Div zero;
End;

Begin
    Writeln('Running rtpkgnone tests');

    stub := PeekW(tgtSetLength);
    If PeekW(tgtFileOpen) <> stub + 3 Then Error(1);
    If PeekW(tgtFileClose) <> stub + 3 Then Error(2);
    If PeekW(tgtReadBytes) <> stub + 3 Then Error(3);
    If PeekW(tgtSine) <> stub + 6 Then Error(4);
    If PeekW(tgtCosine) <> stub + 6 Then Error(5);
    If PeekW(tgtTangent) <> stub + 6 Then Error(6);
End.
