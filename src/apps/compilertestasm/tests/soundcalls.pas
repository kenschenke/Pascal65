Program SoundCalls;

// Calls every routine in the Sound library and uses every constant. It is
// compiled and linked but not run, so a mismatch between sound.pas,
// sound.hdr and the library's jump table fails the compile.

Uses Sound;

Var
    b : Byte;

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
End.
