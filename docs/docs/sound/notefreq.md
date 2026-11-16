# NoteFreq

Returns the SID frequency of a note number.

## Declaration

    Uses Sound;

    Function NoteFreq(note : Word) : Word;

## Description

*NoteFreq* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This function returns the SID frequency value of a note, for
*SetFrequency*, *PlayFreq* or *Sweep*. The notes are tuned with A4 at
440 Hz. The MEGA65's SIDs run from the video clock, so the value depends
on whether the machine is in PAL or NTSC mode. *NoteFreq* checks the mode
each time it's called.

A note's number is its octave times 12 plus its place in the octave,
which the library's constants give (*NoteC* to *NoteB*). [Notes](notes.md)
lists them all. B7 is above the highest frequency a SID can play on PAL,
so *NoteFreq* returns 65,535 for it there.

## Parameters

### note

The note number, 0 (C0) to 95 (B7). A note over 95 returns 0. It is a
Word so a sum such as `4 * 12 + NoteA` can be passed without a warning.

## Example

```
Program example;

Uses Sound;

Begin
    Writeln('A4 is ', NoteFreq(4 * 12 + NoteA));    // 7493 on PAL
End.
```
