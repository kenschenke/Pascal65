# IsPlaying

Returns True while a voice plays a note or a sequence.

## Declaration

    Uses Sound;

    Function IsPlaying(voice : Byte) : Boolean;

## Description

*IsPlaying* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This function returns True from the time *PlayNote*, *PlayFreq* or
*PlaySequence* starts a voice until its timed note's gate closes or its
sequence ends, and False after. A sequence is playing even during a rest.
*StopVoice* and *StopAll* make it False at once.

It goes False when the release starts, not when the sound has faded out.
*SetGate* doesn't change it.

A program can call it in its main loop to start the next sound when a
voice is free, without waiting.

## Parameters

### voice

The voice number, 1 to 12. A bad number returns False.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WavePulse);
    SetPulseWidth(1, 2048);
    SetEnvelope(1, 0, 0, 15, 7);
    PlayNote(1, 5 * 12 + NoteB, 4);
    While IsPlaying(1) Do Begin End;
    PlayNote(1, 6 * 12 + NoteE, 12);
End.
```
