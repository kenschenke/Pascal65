Program RtPkgB;
(* $StaticRuntime *)

// Tests the dynamic arrays and trig runtime packages without files. Trig
// follows dynamic arrays (dynarrays1a, trig1b). The program declares no
// file variable, so the files package must not be linked: its jump table
// entries still point at the core's stub.
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

Var
    zero : Integer;
    i : Integer;
    r : Real;
    ints : Array Of Integer;
    reals : Array Of Real;

Procedure Error(num : Integer);
Begin
    Writeln('RtPkgB (', num, ') failed');
    // A runtime error ends the chain, which fails the tests
    zero := 0;
    zero := 1 Div zero;
End;

Begin
    Writeln('Running rtpkgb tests');

    // Files isn't linked: its entries all point at the same stub, which
    // is 3 bytes past where the dynamic arrays stub would be
    If PeekW(tgtFileOpen) <> PeekW(tgtFileClose) Then Error(1);
    If PeekW(tgtFileOpen) <> PeekW(tgtReadBytes) Then Error(2);

    // Dynamic arrays and trig are linked
    If PeekW(tgtSetLength) + 3 = PeekW(tgtFileOpen) Then Error(3);
    If PeekW(tgtSine) = PeekW(tgtCosine) Then Error(4);

    // And work
    SetLength(ints, 8);
    For i := 0 To 7 Do ints[i] := i * 3;
    SetLength(ints, 12);
    If Length(ints) <> 12 Then Error(5);
    If ints[7] <> 21 Then Error(6);
    If ints[11] <> 0 Then Error(7);

    SetLength(reals, 4);
    For i := 0 To 3 Do reals[i] := Sin(i * 0.5);
    If Abs(reals[0]) > 0.001 Then Error(8);
    If Abs(reals[3] - 0.997495) > 0.001 Then Error(9);
    r := Cos(0.0);
    If Abs(r - 1.0) > 0.001 Then Error(10);
End.
