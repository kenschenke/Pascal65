# Vibrato

Swings a voice's frequency up and down.

## Declaration

    Uses Sound;

    Procedure Vibrato(voice, depth, frames : Byte);

## Description

*Vibrato* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure swings the voice's frequency above and below its note in a
triangle wave, and returns at once. The raster interrupt moves the swing
on each frame. It takes *frames* frames to swing from the top to the
bottom, so a whole swing, up and back, takes twice that. The frequency
goes *depth* / 1024 of the note's frequency each way, so a depth sounds
the same on every note:

|depth|Swing each way|About                    |
|-----|--------------|-------------------------|
|5    |0.5%          |8 cents, a gentle vibrato|
|10   |1%            |17 cents                 |
|60   |6%            |1 semitone               |
|255  |25%           |4 semitones up, 5 down   |

The vibrato stays on from note to note: *PlayNote*, *PlayFreq*,
*SetFrequency* and the notes of a sequence start it over from the new
frequency. *StopVoice* and *StopAll* end it. The frequency never goes
over 65,535.

[Effects](effects.md) has more about the effects and how they combine.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### depth

How far the frequency swings, in 1024ths of the note's frequency each
way. 0 turns the vibrato off and puts the note's frequency back.

### frames

The frames a swing from the top to the bottom takes. 0 turns the vibrato
off.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WaveSaw);
    SetEnvelope(1, 4, 0, 15, 8);
    Vibrato(1, 8, 6);               // A gentle vibrato on every note
    PlayNote(1, 4 * 12 + NoteE, 50);
End.
```
