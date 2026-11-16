# FrameRate

Returns the frames a second, 50 or 60.

## Declaration

    Uses Sound;

    Function FrameRate : Byte;

## Description

*FrameRate* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

The library times notes, effects and sequences in frames, counted by the
raster interrupt. A PAL MEGA65 shows 50 frames a second and an NTSC one
60. This function returns which, so a program can work out a time in
seconds the same way on either.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WaveTriangle);
    PlayNote(1, 4 * 12 + NoteA, FrameRate);     // One second
End.
```
