Program SoundTest;

// Tests the Sound library. Sound can't be heard in a test, and xmega65
// doesn't model the SIDs' OSC3 and ENV3 registers (SIDs 1 and 2 read
// noise and 3 and 4 read $FF), so this checks what reads back the same
// every time: the SID mode register ($D63C) and bad voice and SID numbers.

Uses Sound;

Const
    SidMode = $D63C;

Var
    anyErrors : Boolean;
    errList : String;
    mode, b : Byte;

Procedure Error(num : Integer);
Begin
    Writeln('SoundTest (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'soundtest:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    Writeln('Running sound tests');

    anyErrors := false;
    errList := '';

    // Bad SID numbers return 0
    If GetOsc3(0) <> 0 Then Error(1);
    If GetOsc3(5) <> 0 Then Error(2);
    If GetEnv3(0) <> 0 Then Error(3);
    If GetEnv3(5) <> 0 Then Error(4);

    // Bad voice and SID numbers are ignored. A write through a bad number
    // that strayed out of the SID registers could crash the program.
    SetGate(0, True);
    SetGate(13, True);
    SetGate(255, True);
    SetRingMod(0, True);
    SetSync(13, True);
    FilterVoice(0, True);
    SetFrequency(0, 1000);
    SetPulseWidth(13, 1000);
    SetEnvelope(0, 15, 15, 0, 15);
    SetEnvelope(13, 15, 15, 0, 15);
    SetWaveform(0, WaveNoise);
    SetWaveform(13, WaveNoise);
    SetVolume(0, 0);
    SetVolume(5, 0);
    SetFilter(0, 0, 0, 0);
    SetFilter(5, 0, 0, 0);

    // SetSidMode changes only its SID's bit, which aren't in SID order
    mode := Peek(SidMode);
    b := mode & 240;
    Poke(SidMode, b);
    SetSidMode(1, True);
    If (Peek(SidMode) & 15) <> 2 Then Error(40);
    SetSidMode(2, True);
    If (Peek(SidMode) & 15) <> 10 Then Error(41);
    SetSidMode(3, True);
    If (Peek(SidMode) & 15) <> 11 Then Error(42);
    SetSidMode(4, True);
    If (Peek(SidMode) & 15) <> 15 Then Error(43);
    SetSidMode(1, False);
    If (Peek(SidMode) & 15) <> 13 Then Error(44);
    SetSidMode(0, False);
    SetSidMode(5, False);
    If (Peek(SidMode) & 15) <> 13 Then Error(45);
    SetSidMode(4, False);
    If (Peek(SidMode) & 15) <> 9 Then Error(46);
    Poke(SidMode, mode);

    If anyErrors Then ReportFailure;
End.
