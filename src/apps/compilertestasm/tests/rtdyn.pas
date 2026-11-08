Program RtDyn;

// Tests the dynamic runtime (the default without $StaticRuntime). The
// program's loader loads runtime1 at the top of memory and copies its jump
// table to RT_BASE. Every package is in the dynamic runtime, so every jump
// table entry must point at its own routine there, never at a "package not
// linked" stub, and the program can use dynamic arrays, files and trig
// without linking anything.

Const
    // The target of each jump table entry (RT_BASE $2028 + offset + 1)
    tgtStackCleanup = $2029;
    tgtSetLength = $2179;
    tgtFileOpen = $203B;
    tgtReadBytes = $2161;
    tgtSine = $2146;
    tgtTangent = $214C;
    // The dynamic runtime is far above this small program
    rtAbove = $4000;

Type
    TIntArr = Array Of Integer;

Var
    anyErrors : Boolean;
    errList : String;
    nums : TIntArr;
    i : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('RtDyn (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure CheckEntry(addr : Word; num : Integer);
Begin
    If PeekW(addr) < rtAbove Then Error(num);
End;

Procedure ReportFailure;
Var
    f : Text;
    acc : String;
Begin
    // Keep entries from earlier tests
    acc := '';
    Assign(f, 'testfailed');
    Reset(f);
    If IOResult = 0 Then Readln(f, acc);
    Close(f);
    If Length(acc) < 150 Then acc := acc + 'rtdyn:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running rtdyn tests');

    // The jump table points into the loaded runtime
    CheckEntry(tgtStackCleanup, 1);
    CheckEntry(tgtSetLength, 2);
    CheckEntry(tgtFileOpen, 3);
    CheckEntry(tgtReadBytes, 4);
    CheckEntry(tgtSine, 5);
    CheckEntry(tgtTangent, 6);

    // The packages' entries aren't the stubs, which are 3 bytes apart
    If PeekW(tgtFileOpen) = PeekW(tgtSetLength) + 3 Then Error(7);
    If PeekW(tgtSine) = PeekW(tgtSetLength) + 6 Then Error(8);

    // Each package works
    SetLength(nums, 5);
    For i := 0 To 4 Do nums[i] := i * 10;
    If Length(nums) <> 5 Then Error(9);
    If nums[4] <> 40 Then Error(10);
    If Abs(Sin(0.0)) > 0.001 Then Error(11);
    If Abs(Cos(0.0) - 1.0) > 0.001 Then Error(12);
    If Abs(Tan(0.0)) > 0.001 Then Error(13);

    If anyErrors Then ReportFailure;
End.
