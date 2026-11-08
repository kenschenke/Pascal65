Program RtPkgC;

// Tests all three runtime packages in one program: dynamic arrays, then
// files, then trig (dynarrays1a, files1b, trig1d). Every package's jump
// table entries must point at its own routines.

Const
    // The target of each jump table entry (RT_BASE $2028 + offset + 1)
    tgtSetLength = $2179;
    tgtFileOpen = $203B;
    tgtFileClose = $2050;
    tgtSine = $2146;
    tgtCosine = $2149;

Var
    anyErrors : Boolean;
    errList : String;
    i : Integer;
    ints : Array Of Integer;
    f : Text;
    s : String;

Procedure Error(num : Integer);
Begin
    Writeln('RtPkgC (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
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
    If Length(acc) < 150 Then acc := acc + 'rtpkgc:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running rtpkgc tests');

    // Every package is linked
    If PeekW(tgtSetLength) + 3 = PeekW(tgtFileOpen) Then Error(1);
    If PeekW(tgtFileOpen) = PeekW(tgtFileClose) Then Error(2);
    If PeekW(tgtSine) = PeekW(tgtCosine) Then Error(3);

    // Dynamic arrays
    SetLength(ints, 6);
    For i := 0 To 5 Do ints[i] := i + 100;
    If Length(ints) <> 6 Then Error(4);
    If ints[5] <> 105 Then Error(5);

    // Trig
    If Abs(Sin(1.570795) - 1.0) > 0.001 Then Error(6);
    If Abs(Tan(0.785398) - 1.0) > 0.01 Then Error(7);

    // Files
    Assign(f, 'rtpkgc.dat');
    Rewrite(f);
    If IOResult <> 0 Then Error(8);
    Writeln(f, 'package');
    Close(f);
    Reset(f);
    If IOResult <> 0 Then Error(9);
    Readln(f, s);
    Close(f);
    If CompareStr(s, 'package') <> 0 Then Error(10);
    Erase(f);
    If IOResult <> 0 Then Error(11);

    If anyErrors Then ReportFailure;
End.
