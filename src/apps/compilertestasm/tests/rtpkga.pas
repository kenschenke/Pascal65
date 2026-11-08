Program RtPkgA;
(* $StaticRuntime *)

// Tests the trig runtime package on its own, right after the core
// (trig1a). The program calls Sin, Cos and Tan, and declares no file
// variable (only a file parameter) and calls no SetLength, so those two
// packages must not be linked: their jump table entries still point at
// the core's stubs.
//
// The stubs are 3 bytes apart, in package order (see rterror.s): the
// dynamic arrays stub, then files, then trig.
//
// Without a file variable this test can't write the testfailed file, so
// a failure prints its number and ends the chain with a runtime error.

Const
    // The target of each jump table entry (RT_BASE $2028 + offset + 1)
    tgtSetLength = $2179;
    tgtFileOpen = $203B;
    tgtFileClose = $2050;
    tgtSine = $2146;
    tgtCosine = $2149;
    tgtTangent = $214C;

Var
    zero : Integer;
    stub : Word;
    r : Real;

Procedure Error(num : Integer);
Begin
    Writeln('RtPkgA (', num, ') failed');
    // A runtime error ends the chain, which fails the tests
    zero := 0;
    zero := 1 Div zero;
End;

// A file parameter isn't a file variable: it doesn't link the files
// package. This is never called.
Procedure FileParam(Var f : Text);
Begin
    Close(f);
End;

Begin
    Writeln('Running rtpkga tests');

    // Dynamic arrays and files aren't linked
    stub := PeekW(tgtSetLength);
    If PeekW(tgtFileOpen) <> stub + 3 Then Error(1);
    If PeekW(tgtFileClose) <> stub + 3 Then Error(2);

    // Trig is linked
    If PeekW(tgtSine) = stub + 6 Then Error(3);
    If PeekW(tgtSine) = PeekW(tgtCosine) Then Error(4);
    If PeekW(tgtCosine) = PeekW(tgtTangent) Then Error(5);

    // And works
    r := Sin(1.570795);
    If Abs(r - 1.0) > 0.001 Then Error(6);
    r := Cos(3.14159);
    If Abs(r + 1.0) > 0.001 Then Error(7);
    r := Tan(0.785398);
    If Abs(r - 1.0) > 0.01 Then Error(8);
End.
