# SetFrequency

Sets a voice's frequency.

## Declaration

    Uses Sound;

    Procedure SetFrequency(voice : Byte; freq : Word);

## Description

*SetFrequency* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure sets the pitch of a voice without opening its gate. The
value is the SID's frequency value, not hertz: hertz times 17.03 on a PAL
MEGA65 and times 16.40 on an NTSC one. *NoteFreq* gives a note's value
for either.

Changing the frequency while a voice plays changes its pitch at once,
without starting the envelope over. It ends a *Sweep* on the voice and
starts its *Vibrato* over from the new frequency.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### freq

The SID frequency value, 0 to 65,535.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WaveTriangle);
    SetEnvelope(1, 0, 0, 15, 6);
    SetFrequency(1, NoteFreq(4 * 12 + NoteA));
    SetGate(1, True);
End.
```
