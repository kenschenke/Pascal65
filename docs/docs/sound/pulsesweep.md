# PulseSweep

Moves a voice's pulse width back and forth.

## Declaration

    Uses Sound;

    Procedure PulseSweep(voice : Byte; stepSize : Integer);

## Description

*PulseSweep* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure makes the raster interrupt add *stepSize* to the voice's
pulse width each frame, starting from the width *SetPulseWidth* gave it.
When the width would go past 3968 or under 128, it stops there and turns
around, so it moves back and forth until it's turned off. Sweeping the
pulse width makes a pulse wave shimmer, like a chorus of voices. It only
changes a pulse wave (*WavePulse*).

The sweep stays on from note to note. *SetPulseWidth* during a sweep
moves the width, and the sweep goes on from there. *StopVoice* and
*StopAll* end it.

[Effects](effects.md) has more about the effects and how they combine.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### stepSize

The amount added to the width each frame. A negative step starts it
falling. 0 turns the sweep off and leaves the width where it is.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(8, WavePulse);
    SetPulseWidth(8, 512);
    SetEnvelope(8, 8, 6, 10, 10);
    PlayNote(8, 3 * 12 + NoteC, 100);
    PulseSweep(8, 24);
End.
```
