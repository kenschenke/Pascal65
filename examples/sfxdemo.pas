(*
 * Ken Schenke (kenschenke@gmail.com)
 *
 * Sound effects using the Sound library
 *
 * Copyright (c) 2026
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Program SfxDemo;

// Plays a sound effect for each key. The effects run on the raster
// interrupt, so the menu goes on reading keys while they play. Each
// effect has a voice of its own, so they can be played together.

Uses Sound;

Const
    LaserVoice = 1;
    ExplodeVoice = 2;       // Voice 2 is on SID 1, which filters it
    CoinVoice = 3;
    JumpVoice = 4;
    SirenVoice = 5;
    AlarmVoice = 6;
    EngineVoice = 7;
    PadVoice = 8;

Var
    ch : Char;
    coinWaiting, sirenOn, alarmOn, engineOn : Boolean;

Procedure ShowMenu;
Begin
    Writeln('Sound effects demo');
    Writeln;
    Writeln('  1  Laser');
    Writeln('  2  Explosion');
    Writeln('  3  Coin');
    Writeln('  4  Jump');
    Writeln('  5  Siren (on / off)');
    Writeln('  6  Alarm (on / off)');
    Writeln('  7  Engine (on / off)');
    Writeln('  8  Pulse width pad');
    Writeln('  0  Stop everything');
    Writeln('  Q  Quit');
    Writeln;
End;

// The waveforms and envelopes stay set, so they are set once here
Procedure SetUpVoices;
Begin
    // A narrow pulse that cuts off fast
    SetWaveform(LaserVoice, WavePulse);
    SetPulseWidth(LaserVoice, 1024);
    SetEnvelope(LaserVoice, 0, 0, 15, 6);

    // Noise through SID 1's low pass filter, with a long release
    SetWaveform(ExplodeVoice, WaveNoise);
    SetEnvelope(ExplodeVoice, 0, 0, 15, 11);
    FilterVoice(ExplodeVoice, True);

    // A square wave
    SetWaveform(CoinVoice, WavePulse);
    SetPulseWidth(CoinVoice, 2048);
    SetEnvelope(CoinVoice, 0, 0, 15, 7);

    // A soft triangle
    SetWaveform(JumpVoice, WaveTriangle);
    SetEnvelope(JumpVoice, 0, 0, 15, 4);

    // A sawtooth that fades in and out a little
    SetWaveform(SirenVoice, WaveSaw);
    SetEnvelope(SirenVoice, 2, 0, 15, 6);

    // A square wave
    SetWaveform(AlarmVoice, WavePulse);
    SetPulseWidth(AlarmVoice, 2048);
    SetEnvelope(AlarmVoice, 0, 0, 15, 3);

    // A low sawtooth that starts and stops slowly
    SetWaveform(EngineVoice, WaveSaw);
    SetEnvelope(EngineVoice, 6, 0, 15, 8);

    // A pulse that swells, then holds lower
    SetWaveform(PadVoice, WavePulse);
    SetPulseWidth(PadVoice, 512);
    SetEnvelope(PadVoice, 8, 6, 10, 10);
End;

// A high note that falls fast, still falling as it fades
Procedure Laser;
Begin
    Writeln('Laser');
    PlayFreq(LaserVoice, 40000, 8);
    Sweep(LaserVoice, 40000, 3000, 14);
End;

// Noise that rumbles lower as the filter closes over a second and a half
Procedure Explosion;
Begin
    Writeln('Explosion');
    SetFilter(1, 2047, 10, FilterLow);
    PlayFreq(ExplodeVoice, 3000, 6);
    Sweep(ExplodeVoice, 3000, 600, 75);
    FilterSweep(1, 40, 75);
End;

// Two quick notes. The second starts in the main loop when the first
// ends (coinWaiting), so the program doesn't wait for it.
Procedure Coin;
Begin
    Writeln('Coin');
    PlayNote(CoinVoice, 5 * 12 + NoteB, 4);
    coinWaiting := True;
End;

// A triangle that rises
Procedure Jump;
Begin
    Writeln('Jump');
    PlayFreq(JumpVoice, 2000, 12);
    Sweep(JumpVoice, 2000, 9000, 14);
End;

// A slow, wide vibrato swings the note up and down about four semitones
// each way, once every 1.2 seconds on PAL
Procedure Siren;
Begin
    sirenOn := Not sirenOn;
    If sirenOn Then Begin
        Writeln('Siren on');
        PlayNote(SirenVoice, 5 * 12 + NoteA, 0);
        Vibrato(SirenVoice, 255, 30);
    End Else Begin
        Writeln('Siren off');
        StopVoice(SirenVoice);
    End;
End;

// A fast vibrato warbles the note
Procedure Alarm;
Begin
    alarmOn := Not alarmOn;
    If alarmOn Then Begin
        Writeln('Alarm on');
        PlayNote(AlarmVoice, 6 * 12 + NoteC, 0);
        Vibrato(AlarmVoice, 120, 3);
    End Else Begin
        Writeln('Alarm off');
        StopVoice(AlarmVoice);
    End;
End;

// A low note with a fast, shallow vibrato rumbles like a motor
Procedure Engine;
Begin
    engineOn := Not engineOn;
    If engineOn Then Begin
        Writeln('Engine on');
        PlayNote(EngineVoice, 1 * 12 + NoteA, 0);
        Vibrato(EngineVoice, 30, 2);
    End Else Begin
        Writeln('Engine off');
        StopVoice(EngineVoice);
    End;
End;

// The pulse width sweeping back and forth makes the tone shimmer. The
// sweep goes on through the release.
Procedure Pad;
Begin
    Writeln('Pad');
    PlayNote(PadVoice, 3 * 12 + NoteC, 100);
    PulseSweep(PadVoice, 24);
End;

Procedure StopEverything;
Begin
    Writeln('Stop');
    StopAll;
    coinWaiting := False;
    sirenOn := False;
    alarmOn := False;
    engineOn := False;
End;

Begin
    coinWaiting := False;
    sirenOn := False;
    alarmOn := False;
    engineOn := False;
    SetUpVoices;
    ShowMenu;

    Repeat
        ch := GetKeyNoWait;
        Case ch Of
            '1': Laser;
            '2': Explosion;
            '3': Coin;
            '4': Jump;
            '5': Siren;
            '6': Alarm;
            '7': Engine;
            '8': Pad;
            '0': StopEverything;
        End;
        If coinWaiting And Not IsPlaying(CoinVoice) Then Begin
            PlayNote(CoinVoice, 6 * 12 + NoteE, 12);
            coinWaiting := False;
        End;
    Until (ch = 'q') Or (ch = 'Q');
End.
