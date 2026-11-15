Program SoundFx;

// Tests the Sound library's effects (Sweep, Vibrato, PulseSweep and
// FilterSweep). The SID registers can't be read back, so this checks the
// values the library writes to them (GetFrequency, GetPulseWidth and
// GetCutoff). soundtest has the other tests.
//
// The library runs the effects on the raster interrupt at line 210.
// WaitFrames counts the frames by watching the raster pass line 256 and
// go back to 0, so after n frames the interrupt has run n - 1 or n times.
// Right after WaitFrames the raster is near line 0, so an effect started
// then sees exactly n interrupts in the next n frames.

Uses Sound;

Const
    VicCtrl1 = $D011;   // Bit 7 is bit 8 of the raster line

Var
    anyErrors : Boolean;
    errList : String;
    i : Byte;
    f, minW, maxW : Word;
    outside : Boolean;
    targets : Array[1..12] Of Word = (1000, 2000, 3000, 4000, 5000, 6000,
        7000, 8000, 9000, 10000, 11000, 12000);
    cutoffs : Array[1..4] Of Word = (100, 200, 300, 2047);

Procedure Error(num : Integer);
Begin
    Writeln('SoundFx (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

// Fails test num if actual isn't expected
Procedure Expect(actual, expected : Word; num : Integer);
Begin
    If actual <> expected Then Error(num);
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

// Reads a voice's frequency (kind 0) or pulse width (1) once a frame for
// a number of frames and sets minW and maxW. outside is True if a pulse
// width went past 128 to 3968.
Procedure Sample(voice, kind, count : Byte);
Var
    n : Byte;
    w : Word;
Begin
    minW := 65535;
    maxW := 0;
    outside := False;
    For n := 1 To count Do Begin
        WaitFrames(1);
        If kind = 0 Then w := GetFrequency(voice)
        Else w := GetPulseWidth(voice);
        If w < minW Then minW := w;
        If w > maxW Then maxW := w;
        If (kind = 1) And ((w < 128) Or (w > 3968)) Then outside := True;
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
    If Length(acc) < 150 Then acc := acc + 'soundfx:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    Writeln('Running sound effects tests');

    anyErrors := false;
    errList := '';

    // Give the voices a sound so the effects can be heard when the test
    // is run by hand. It doesn't change what the test sees.
    SetVolume(1, 15);
    For i := 1 To 12 Do Begin
        SetWaveform(i, WaveTriangle);
        SetEnvelope(i, 0, 0, 15, 0);
    End;

    // Effects with bad voice and SID numbers are ignored
    Sweep(0, 1000, 2000, 10);
    Sweep(13, 1000, 2000, 10);
    Vibrato(0, 10, 10);
    Vibrato(13, 10, 10);
    PulseSweep(0, 10);
    PulseSweep(13, 10);
    FilterSweep(0, 1000, 10);
    FilterSweep(5, 1000, 10);
    Expect(GetFrequency(0), 0, 100);
    Expect(GetFrequency(13), 0, 101);
    Expect(GetPulseWidth(0), 0, 102);
    Expect(GetPulseWidth(13), 0, 103);
    Expect(GetCutoff(0), 0, 104);
    Expect(GetCutoff(5), 0, 105);

    // The getters read back what the layer 1 and note calls set
    SetFrequency(1, 4321);
    Expect(GetFrequency(1), 4321, 110);
    PlayFreq(1, 7493, 1);
    Expect(GetFrequency(1), 7493, 111);
    PlayNote(2, 57, 1);
    Expect(GetFrequency(2), NoteFreq(57), 112);
    SetPulseWidth(1, 2048);
    Expect(GetPulseWidth(1), 2048, 113);
    SetPulseWidth(1, 5000);             // 12 bits
    Expect(GetPulseWidth(1), 904, 114);
    SetFilter(1, 1500, 0, FilterLow);
    Expect(GetCutoff(1), 1500, 115);
    SetFilter(2, 3000, 0, FilterLow);   // 11 bits
    Expect(GetCutoff(2), 952, 116);

    // A rising sweep, 100 a frame, ends on its target and stays there
    WaitFrames(1);
    Sweep(1, 1000, 2000, 10);
    Expect(GetFrequency(1), 1000, 120);
    WaitFrames(5);
    f := GetFrequency(1);
    If (f <> 1400) And (f <> 1500) Then Error(121);
    WaitFrames(7);
    Expect(GetFrequency(1), 2000, 122);
    WaitFrames(2);
    Expect(GetFrequency(1), 2000, 123);

    // A falling sweep, 1000 a frame
    WaitFrames(1);
    Sweep(2, 30000, 1000, 29);
    WaitFrames(10);
    f := GetFrequency(2);
    If (f <> 21000) And (f <> 20000) Then Error(124);
    WaitFrames(21);
    Expect(GetFrequency(2), 1000, 125);

    // A step under 1 still gets there, and the ends of the range
    Sweep(3, 100, 103, 7);
    Sweep(4, 65535, 0, 2);
    Sweep(5, 0, 65535, 1);
    WaitFrames(9);
    Expect(GetFrequency(3), 103, 126);
    Expect(GetFrequency(4), 0, 127);
    Expect(GetFrequency(5), 65535, 128);

    // 0 frames sets the target at once
    Sweep(6, 1000, 2000, 0);
    Expect(GetFrequency(6), 2000, 129);

    // A note or SetFrequency ends a sweep
    Sweep(1, 1000, 2000, 50);
    PlayFreq(1, 5000, 0);
    WaitFrames(3);
    Expect(GetFrequency(1), 5000, 130);
    Sweep(2, 1000, 2000, 50);
    SetFrequency(2, 3000);
    WaitFrames(3);
    Expect(GetFrequency(2), 3000, 131);

    // StopVoice ends a sweep where it is
    Sweep(3, 1000, 2000, 50);
    WaitFrames(3);
    StopVoice(1);
    StopVoice(3);
    f := GetFrequency(3);
    If (f <= 1000) Or (f >= 2000) Then Error(132);
    WaitFrames(3);
    Expect(GetFrequency(3), f, 133);

    // A sweep goes on after its note ends
    PlayFreq(5, 1000, 2);
    Sweep(5, 1000, 2000, 10);
    WaitFrames(13);
    If IsPlaying(5) Then Error(134);
    Expect(GetFrequency(5), 2000, 135);

    // Vibrato: 10240 * 100 / 1024 is 1000 above and below, in steps of
    // 200, 5 frames up, then 10 down and 10 up
    SetFrequency(6, 10240);
    WaitFrames(1);
    Vibrato(6, 100, 10);
    Expect(GetFrequency(6), 10240, 140);
    Sample(6, 0, 30);
    If maxW <> 11240 Then Error(141);
    If minW <> 9240 Then Error(142);
    Vibrato(6, 0, 10);                  // Off
    Expect(GetFrequency(6), 10240, 143);
    WaitFrames(2);
    Expect(GetFrequency(6), 10240, 144);

    // A note keeps the vibrato and starts it over from its frequency
    Vibrato(7, 100, 10);
    WaitFrames(3);
    WaitFrames(1);
    PlayFreq(7, 20480, 0);
    Expect(GetFrequency(7), 20480, 145);
    Sample(7, 0, 30);
    If maxW <> 22480 Then Error(146);
    If minW <> 18480 Then Error(147);

    // StopVoice ends the vibrato and puts the base frequency back
    StopVoice(7);
    Expect(GetFrequency(7), 20480, 148);
    WaitFrames(2);
    Expect(GetFrequency(7), 20480, 149);

    // Vibrato stays under 65536, and 0 frames turns it off
    SetFrequency(8, 65000);
    Vibrato(8, 255, 4);
    Sample(8, 0, 10);
    If maxW <> 65535 Then Error(150);
    If minW > 50000 Then Error(151);
    Vibrato(8, 255, 0);
    Expect(GetFrequency(8), 65000, 152);

    // A pulse sweep turns around at 128 and 3968
    SetPulseWidth(9, 2000);
    WaitFrames(1);
    PulseSweep(9, 100);
    WaitFrames(5);
    f := GetPulseWidth(9);
    If (f <> 2400) And (f <> 2500) Then Error(160);
    Sample(9, 1, 80);
    If outside Then Error(161);
    If maxW <> 3968 Then Error(162);
    If minW <> 128 Then Error(163);
    PulseSweep(9, 0);                   // Off
    f := GetPulseWidth(9);
    WaitFrames(3);
    Expect(GetPulseWidth(9), f, 164);

    // Falling first, and a step bigger than the range
    SetPulseWidth(10, 300);
    PulseSweep(10, -100);
    Sample(10, 1, 10);
    If outside Then Error(165);
    If minW <> 128 Then Error(166);
    SetPulseWidth(11, 0);
    PulseSweep(11, 32767);
    Sample(11, 1, 6);
    If outside Then Error(167);
    If (minW <> 128) Or (maxW <> 3968) Then Error(168);

    // SetPulseWidth during a sweep: it goes on from there
    WaitFrames(1);
    SetPulseWidth(10, 1000);
    Expect(GetPulseWidth(10), 1000, 169);
    WaitFrames(1);
    f := GetPulseWidth(10);
    If (f <> 900) And (f <> 1100) Then Error(170);
    StopVoice(10);
    StopVoice(11);
    f := GetPulseWidth(11);
    WaitFrames(2);
    Expect(GetPulseWidth(11), f, 171);

    // A filter sweep starts from the cutoff, 100 a frame
    SetFilter(1, 0, 0, FilterLow);
    WaitFrames(1);
    FilterSweep(1, 2000, 20);
    WaitFrames(10);
    f := GetCutoff(1);
    If (f <> 900) And (f <> 1000) Then Error(180);
    WaitFrames(12);
    Expect(GetCutoff(1), 2000, 181);
    WaitFrames(1);
    FilterSweep(1, 0, 4);
    WaitFrames(2);
    f := GetCutoff(1);
    If (f <> 1500) And (f <> 1000) Then Error(182);
    WaitFrames(4);
    Expect(GetCutoff(1), 0, 183);

    // 0 frames and a target over 11 bits
    FilterSweep(2, 5000, 0);
    Expect(GetCutoff(2), 904, 184);

    // SetFilter ends a filter sweep, and so does StopAll
    FilterSweep(3, 2047, 100);
    SetFilter(3, 10, 0, FilterLow);
    WaitFrames(3);
    Expect(GetCutoff(3), 10, 185);
    FilterSweep(4, 2047, 100);
    WaitFrames(3);
    StopAll;
    f := GetCutoff(4);
    If f = 0 Then Error(186);
    WaitFrames(3);
    Expect(GetCutoff(4), f, 187);

    // Every effect on every voice at once
    For i := 1 To 12 Do Begin
        SetPulseWidth(i, 2048);
        PulseSweep(i, 50);
        Vibrato(i, 20, 6);
        Sweep(i, 0, targets[i], 10);
    End;
    For i := 1 To 4 Do FilterSweep(i, cutoffs[i], 10);
    WaitFrames(12);
    For i := 1 To 4 Do
        Expect(GetCutoff(i), cutoffs[i], 190);
    For i := 1 To 12 Do Vibrato(i, 0, 0);
    For i := 1 To 12 Do
        Expect(GetFrequency(i), targets[i], 191);
    StopAll;
    For i := 1 To 12 Do Begin
        f := GetPulseWidth(i);
        If (f < 128) Or (f > 3968) Then Error(192);
    End;

    StopAll;

    If anyErrors Then ReportFailure;
End.
