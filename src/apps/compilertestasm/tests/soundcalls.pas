Program SoundCalls;

// Calls every routine in the Sound library and uses every constant. It is
// compiled and linked but not run, so a mismatch between sound.pas,
// sound.hdr and the library's jump table fails the compile.

Uses Sound;

Var
    scale : Array[1..8] Of Byte = (0, 2, 4, 5, 7, 9, 11, 12);
    b, i, octave : Byte;
    w : Word;
    playing : Boolean;

Begin
    SetSidMode(1, False);
    SetVolume(1, 15);
    SetWaveform(1, WaveTriangle);
    SetWaveform(2, WaveSaw);
    SetWaveform(3, WavePulse);
    SetWaveform(4, WaveNoise);
    SetEnvelope(1, 0, 9, 0, 0);
    SetFrequency(1, 7217);
    SetPulseWidth(3, 2048);
    SetGate(1, True);
    SetRingMod(1, True);
    SetSync(1, True);
    SetFilter(1, 1024, 8, FilterLow + FilterBand + FilterHigh);
    FilterVoice(1, True);
    b := GetOsc3(1);
    b := GetEnv3(1);
    octave := 4;
    w := NoteFreq(octave * 12 + NoteA);
    PlayNote(1, octave * 12 + NoteC, 10);
    PlayNote(2, octave * 12 + NoteCSharp, 0);
    PlayNote(3, NoteD + NoteDSharp + NoteE + NoteF + NoteFSharp, 1);
    PlayNote(4, NoteG + NoteGSharp + NoteASharp + NoteB, 1);
    PlayFreq(5, w, 255);
    playing := IsPlaying(1);
    StopVoice(1);
    StopAll;
    b := FrameRate;
    // The example in docs/docs/sound/intro.md
    For i := 1 To 8 Do Begin
        PlayNote(1, octave * 12 + scale[i], 10);
        While IsPlaying(1) Do Write('.');
        Writeln;
    End;
End.
