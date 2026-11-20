Program SoundTest;

// Tests the Sound library. Sound can't be heard in a test, and xmega65
// doesn't model the SIDs' OSC3 and ENV3 registers (SIDs 1 and 2 read
// noise and 3 and 4 read $FF), so this checks what reads back the same
// every time: the SID mode register ($D63C), bad voice and SID numbers,
// note frequencies and how long timed notes play.
//
// The library times notes on the raster interrupt at line 210. WaitFrames
// counts the frames by watching the raster pass line 256 and go back to
// 0, so after n frames the interrupt has run n - 1 or n times.

Uses Sound;

Const
    SidMode = $D63C;
    VicPal = $D06F;     // Bit 7 is 1 on NTSC
    VicCtrl1 = $D011;   // Bit 7 is bit 8 of the raster line

Var
    anyErrors : Boolean;
    errList : String;
    mode, b, i, octave : Byte;
    note : Word;
    isNtsc : Boolean;

Procedure Error(num : Integer);
Begin
    Writeln('SoundTest (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure WaitFrames(count : Byte);
Var
    n : Byte;
Begin
    For n := 1 To count Do Begin
        While (Peek(VicCtrl1) & 128) = 0 Do Begin End;
        While (Peek(VicCtrl1) & 128) <> 0 Do Begin End;
    End;
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
    SetVoice3Off(0, True);
    SetVoice3Off(5, True);
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

    // Bad voice and note numbers
    If IsPlaying(0) Then Error(50);
    If IsPlaying(13) Then Error(51);
    PlayNote(0, 57, 10);
    PlayNote(13, 57, 10);
    PlayFreq(0, 7493, 10);
    PlayFreq(255, 7493, 10);
    StopVoice(0);
    StopVoice(13);
    If NoteFreq(96) <> 0 Then Error(52);
    If NoteFreq(256) <> 0 Then Error(53);
    note := 313;                // 57 in the low byte
    If NoteFreq(note) <> 0 Then Error(54);
    PlayNote(1, 96, 10);
    If IsPlaying(1) Then Error(55);
    PlayNote(1, note, 10);
    If IsPlaying(1) Then Error(56);

    // Note frequencies follow the video mode, as the SIDs' clock does.
    // B7 is past the highest SID frequency on PAL.
    isNtsc := (Peek(VicPal) & 128) <> 0;
    octave := 4;
    If isNtsc Then Begin
        If FrameRate <> 60 Then Error(60);
        If NoteFreq(0) <> 268 Then Error(61);
        If NoteFreq(1) <> 284 Then Error(62);
        If NoteFreq(octave * 12 + NoteA) <> 7218 Then Error(63);
        If NoteFreq(72) <> 17167 Then Error(64);
        If NoteFreq(84) <> 34334 Then Error(65);
        If NoteFreq(94) <> 61178 Then Error(66);
        If NoteFreq(95) <> 64814 Then Error(67);
    End Else Begin
        If FrameRate <> 50 Then Error(70);
        If NoteFreq(0) <> 278 Then Error(71);
        If NoteFreq(1) <> 295 Then Error(72);
        If NoteFreq(octave * 12 + NoteA) <> 7493 Then Error(73);
        If NoteFreq(72) <> 17820 Then Error(74);
        If NoteFreq(84) <> 35640 Then Error(75);
        If NoteFreq(94) <> 63504 Then Error(76);
        If NoteFreq(95) <> 65535 Then Error(77);
    End;

    // Give the voices an envelope so the notes can be heard when the test
    // is run by hand. It doesn't change what the test sees.
    SetVolume(1, 15);
    For i := 1 To 12 Do Begin
        SetWaveform(i, WaveTriangle);
        SetEnvelope(i, 0, 0, 15, 0);
    End;

    // A timed note plays for its frames, then IsPlaying goes false
    PlayNote(1, 57, 10);
    If Not IsPlaying(1) Then Error(80);
    WaitFrames(5);
    If Not IsPlaying(1) Then Error(81);
    WaitFrames(7);
    If IsPlaying(1) Then Error(82);

    // A note of 0 frames plays until it's stopped
    PlayFreq(2, 7493, 0);
    WaitFrames(12);
    If Not IsPlaying(2) Then Error(83);
    StopVoice(2);
    If IsPlaying(2) Then Error(84);

    // A note played again starts its time over
    PlayNote(3, 60, 5);
    PlayNote(3, 60, 20);
    WaitFrames(9);
    If Not IsPlaying(3) Then Error(85);
    StopVoice(3);
    If IsPlaying(3) Then Error(86);

    // StopVoice stops a timed note at once
    PlayNote(4, 60, 100);
    StopVoice(4);
    If IsPlaying(4) Then Error(87);
    WaitFrames(2);
    If IsPlaying(4) Then Error(88);

    // All 12 voices at once, for 2, 4, ... 24 frames. After 13 frames
    // the interrupt has run 12 or 13 times.
    PlayNote(1, 48, 2);
    PlayNote(2, 48, 4);
    PlayNote(3, 48, 6);
    PlayNote(4, 48, 8);
    PlayNote(5, 48, 10);
    PlayNote(6, 48, 12);
    PlayNote(7, 48, 14);
    PlayNote(8, 48, 16);
    PlayNote(9, 48, 18);
    PlayNote(10, 48, 20);
    PlayNote(11, 48, 22);
    PlayNote(12, 48, 24);
    For i := 1 To 12 Do
        If Not IsPlaying(i) Then Error(90);
    WaitFrames(13);
    For i := 1 To 6 Do
        If IsPlaying(i) Then Error(91);
    For i := 7 To 12 Do
        If Not IsPlaying(i) Then Error(92);
    StopAll;
    For i := 1 To 12 Do
        If IsPlaying(i) Then Error(93);

    // Every voice runs out by itself
    For i := 1 To 12 Do PlayNote(i, 36, 3);
    WaitFrames(5);
    For i := 1 To 12 Do
        If IsPlaying(i) Then Error(94);

    If anyErrors Then ReportFailure;
End.
