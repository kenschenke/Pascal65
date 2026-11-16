# StopVoice

Stops a voice's note and starts its release.

## Declaration

    Uses Sound;

    Procedure StopVoice(voice : Byte);

## Description

*StopVoice* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure closes a voice's gate, so its release plays (see
*SetEnvelope*). It ends the voice's timed note or sequence and every
effect on it: *Sweep*, *Vibrato* and *PulseSweep*. *IsPlaying* returns
False at once. The done callback (*SetSoundDoneCallback*) isn't called.

The frequency stays where a sweep left it, without the vibrato's swing,
and the pulse width stays where it is. The waveform and envelope stay
set.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

## Example

```
Program example;

Uses Sound;

Var
    ch : Char;

Begin
    SetWaveform(5, WaveSaw);
    SetEnvelope(5, 2, 0, 15, 6);
    PlayNote(5, 5 * 12 + NoteA, 0);     // Plays until stopped
    Vibrato(5, 255, 30);                // A siren
    ch := GetKey;
    StopVoice(5);
End.
```
