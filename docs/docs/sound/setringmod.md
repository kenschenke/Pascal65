# SetRingMod

Ring modulates a voice with the voice before it.

## Declaration

    Uses Sound;

    Procedure SetRingMod(voice : Byte; on : Boolean);

## Description

*SetRingMod* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

Ring modulation replaces a voice's triangle wave with a mix of its own
frequency and that of the voice before it on the same SID. Two
frequencies that aren't a simple ratio apart make a metallic, bell-like
sound. The voice must have the triangle waveform (*WaveTriangle*). The
other voice supplies only its frequency: it doesn't need a waveform or an
open gate, and it can be kept silent.

Each SID's voices pair up in a ring:

|Voice      |Modulated by|
|-----------|------------|
|1, 4, 7, 10|3, 6, 9, 12 |
|2, 5, 8, 11|1, 4, 7, 10 |
|3, 6, 9, 12|2, 5, 8, 11 |

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### on

*True* turns ring modulation on, *False* turns it off.

## Example

```
Program example;

Uses Sound;

Begin
    SetFrequency(3, 5130);          // Voice 3 is the modulator
    SetWaveform(1, WaveTriangle);
    SetRingMod(1, True);
    SetEnvelope(1, 0, 11, 0, 11);   // A bell rings out
    PlayFreq(1, 7493, 2);
End.
```
