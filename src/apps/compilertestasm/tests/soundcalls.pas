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
    seq : Array[1..16] Of Byte;

Procedure SoundDone(voice : Byte);
Begin
    b := voice;
End;

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
    SetVoice3Off(1, True);
    SetVoice3Off(1, False);
    b := GetOsc3(1);
    b := GetEnv3(1);
    octave := 4;
    w := NoteFreq(octave * 12 + NoteA);
    PlayNote(1, octave * 12 + NoteC, 10);
    PlayNote(2, octave * 12 + NoteCSharp, 0);
    PlayNote(3, NoteD + NoteDSharp + NoteE + NoteF + NoteFSharp, 1);
    PlayNote(4, NoteG + NoteGSharp + NoteASharp + NoteB, 1);
    // Constant expressions with literals don't warn
    w := NoteFreq(4 * 12 + NoteA);
    PlayNote(6, 48 + NoteB, 1);
    PlayNote(7, NoteC + 7 * 12, 1);
    PlayFreq(5, w, 255);
    playing := IsPlaying(1);
    StopVoice(1);
    StopAll;
    b := FrameRate;
    Sweep(1, 30000, 1000, 20);
    Sweep(2, w, NoteFreq(60), 0);
    Vibrato(3, 10, 8);
    Vibrato(3, 0, 0);
    PulseSweep(4, 40);
    PulseSweep(4, -40);
    PulseSweep(4, 0);
    FilterSweep(1, 2047, 50);
    w := GetFrequency(1);
    w := GetPulseWidth(1);
    w := GetCutoff(1);
    seq[1] := SeqTempo;
    seq[2] := 2;
    seq[3] := SeqWave;
    seq[4] := WavePulse;
    seq[5] := SeqEnvelope;
    seq[6] := 9;
    seq[7] := 0;
    seq[8] := SeqPulse;
    seq[9] := 0;
    seq[10] := 8;
    seq[11] := 4 * 12 + NoteA;
    seq[12] := 4;
    seq[13] := SeqRest;
    seq[14] := 4;
    seq[15] := SeqLoop;
    seq[16] := SeqEnd;
    PlaySequence(1, @seq[1]);
    SetSoundDoneCallback(@SoundDone);
    ClearSoundDoneCallback;
    // The example in docs/docs/sound/intro.md
    For i := 1 To 8 Do Begin
        PlayNote(1, octave * 12 + scale[i], 10);
        While IsPlaying(1) Do Write('.');
        Writeln;
    End;
End.
