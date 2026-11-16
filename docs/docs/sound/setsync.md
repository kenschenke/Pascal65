# SetSync

Syncs a voice to the voice before it.

## Declaration

    Uses Sound;

    Procedure SetSync(voice : Byte; on : Boolean);

## Description

*SetSync* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

With sync on, a voice's wave starts over each time the wave of the voice
before it on the same SID does. The voice then plays at the other voice's
pitch, and its own frequency changes its tone instead. Sweeping the
synced voice's frequency gives the tearing lead sound of many synths. The
other voice supplies only its frequency: it doesn't need a waveform or an
open gate.

The voices pair up as for *SetRingMod*: voice 1 is synced to 3, 2 to 1
and 3 to 2, and the same on the other SIDs.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### on

*True* turns sync on, *False* turns it off.

## Example

```
Program example;

Uses Sound;

Begin
    SetFrequency(1, NoteFreq(3 * 12 + NoteC));  // The pitch
    SetWaveform(2, WaveSaw);
    SetSync(2, True);
    SetEnvelope(2, 0, 0, 15, 8);
    PlayFreq(2, 8000, 50);
    Sweep(2, 8000, 30000, 50);      // Sweeps the tone, not the pitch
End.
```
