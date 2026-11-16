# Sweep

Slides a voice's frequency to another.

## Declaration

    Uses Sound;

    Procedure Sweep(voice : Byte; fromFreq, toFreq : Word; frames : Byte);

## Description

*Sweep* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure sets the voice's frequency to *fromFreq* and returns at
once. The raster interrupt then moves the frequency to *toFreq* over
*frames* frames, by the same amount each frame. The last frame sets
*toFreq* exactly, and the frequency stays there.

*Sweep* doesn't open the gate. Start the note first (*PlayFreq* or
*PlayNote*), then the sweep: a note ends a sweep, and so does
*SetFrequency*. A sweep goes on after a timed note ends, through its
release. A *Vibrato* on the voice swings around the sweeping frequency.

[Effects](effects.md) has more about the effects and how they combine.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### fromFreq

The SID frequency value to start from, 0 to 65,535.

### toFreq

The SID frequency value to end on, 0 to 65,535.

### frames

How long the sweep takes, 1 to 255 frames. 0 sets *toFreq* at once.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(4, WaveTriangle);
    SetEnvelope(4, 0, 0, 15, 4);
    PlayFreq(4, 2000, 12);          // A jump
    Sweep(4, 2000, 9000, 14);
End.
```
