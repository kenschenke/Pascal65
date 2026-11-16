# PlayNote

Plays a note for a number of frames.

## Declaration

    Uses Sound;

    Procedure PlayNote(voice : Byte; note : Word; frames : Byte);

## Description

*PlayNote* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure sets a voice's frequency to a note (see *NoteFreq*), opens
its gate and returns at once. The raster interrupt counts the frames and
closes the gate when they run out, so the note's release plays while the
program goes on with its work. A frame is a 50th of a second on a PAL
MEGA65 and a 60th on an NTSC one (*FrameRate*).

Set the voice's waveform and envelope first (*SetWaveform*,
*SetEnvelope*). They stay set from note to note.

If the voice is already playing, its gate is closed and opened again, so
the new note's attack starts over. The note ends a *Sweep* or a sequence
(*PlaySequence*) on the voice. A *Vibrato* or *PulseSweep* goes on, the
vibrato starting over from the new note.

*IsPlaying* is True until the gate closes. When the gate closes the done
callback (*SetSoundDoneCallback*) is called, if one is set.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### note

The note number, 0 (C0) to 95 (B7). See [Notes](notes.md). A note over
95 is ignored.

### frames

How long to hold the gate open, 1 to 255 frames. 0 plays the note until
*StopVoice* or *StopAll* stops it.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WaveTriangle);
    SetEnvelope(1, 0, 6, 8, 6);
    PlayNote(1, 4 * 12 + NoteA, 25);    // A4 for half a second on PAL
    While IsPlaying(1) Do Begin End;
End.
```
