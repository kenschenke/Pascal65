(*
 * Ken Schenke (kenschenke@gmail.com)
 *
 * Sound Library
 *
 * Copyright (c) 2026
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Unit Sound;

Interface

// Voices are numbered 1 to 12 and SIDs 1 to 4. Voice v is on SID
// (v - 1) Div 3 + 1. A bad voice or SID number is ignored.
Const
    // Waveforms for SetWaveform (the bits of the voice's control register)
    WaveTriangle = 16;
    WaveSaw = 32;
    WavePulse = 64;
    WaveNoise = 128;
    // Filter modes for SetFilter. Add them to combine them.
    FilterLow = 16;
    FilterBand = 32;
    FilterHigh = 64;

Procedure SetSidMode(sid : Byte; is8580 : Boolean);
Procedure SetVolume(sid, volume : Byte);
Procedure SetWaveform(voice : Byte; waveform : Word);
Procedure SetEnvelope(voice, attack, decay, sustain, release : Byte);
Procedure SetFrequency(voice : Byte; freq : Word);
Procedure SetPulseWidth(voice : Byte; width : Word);
Procedure SetGate(voice : Byte; on : Boolean);
Procedure SetRingMod(voice : Byte; on : Boolean);
Procedure SetSync(voice : Byte; on : Boolean);
Procedure SetFilter(sid : Byte; cutoff : Word; resonance : Byte; mode : Word);
Procedure FilterVoice(voice : Byte; on : Boolean);
Function GetOsc3(sid : Byte) : Byte;
Function GetEnv3(sid : Byte) : Byte;

Implementation Library

End.
