# StopAll

Stops every voice's note.

## Declaration

    Uses Sound;

    Procedure StopAll;

## Description

*StopAll* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure does what *StopVoice* does for all 12 voices: it closes
their gates, so their releases play, and ends their timed notes,
sequences and effects. It also ends the filter sweeps (*FilterSweep*) of
all four SIDs, leaving their cutoffs where they are. The done callback
(*SetSoundDoneCallback*) isn't called.

The volumes aren't changed. The library stops everything itself when the
program ends, so a program doesn't need to call *StopAll* before it ends.

## Example

```
Program example;

Uses Sound;

Var
    ch : Char;

Begin
    SetWaveform(1, WaveTriangle);
    SetWaveform(4, WaveSaw);
    PlayNote(1, 4 * 12 + NoteC, 0);
    PlayNote(4, 3 * 12 + NoteC, 0);
    ch := GetKey;
    StopAll;
End.
```
