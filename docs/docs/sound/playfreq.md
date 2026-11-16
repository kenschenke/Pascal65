# PlayFreq

Plays a SID frequency for a number of frames.

## Declaration

    Uses Sound;

    Procedure PlayFreq(voice : Byte; freq : Word; frames : Byte);

## Description

*PlayFreq* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure works like *PlayNote*, but takes a SID frequency value in
place of a note number. It suits sound effects, whose pitches aren't
notes. The value is hertz times 17.03 on a PAL MEGA65 and times 16.40 on
an NTSC one.

It sets the voice's frequency, opens its gate and returns at once. The
raster interrupt closes the gate after the given number of frames. As
with *PlayNote*, a voice that is playing starts its attack over, a
*Sweep* or sequence on it ends, and a *Vibrato* starts over from the new
frequency.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### freq

The SID frequency value, 0 to 65,535.

### frames

How long to hold the gate open, 1 to 255 frames. 0 plays until
*StopVoice* or *StopAll* stops it.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WavePulse);
    SetPulseWidth(1, 1024);
    SetEnvelope(1, 0, 0, 15, 6);
    PlayFreq(1, 40000, 8);          // A laser
    Sweep(1, 40000, 3000, 14);
End.
```
