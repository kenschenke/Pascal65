# SetWaveform

Sets a voice's waveform.

## Declaration

    Uses Sound;

    Procedure SetWaveform(voice : Byte; waveform : Word);

## Description

*SetWaveform* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure picks the shape of the wave a voice plays, which sets the
character of its sound:

|Constant    |Value|Sound                                     |
|------------|-----|------------------------------------------|
|WaveTriangle|16   |Soft and hollow, like a flute             |
|WaveSaw     |32   |Bright and buzzy, like brass or strings   |
|WavePulse   |64   |Reedy; its width is set by *SetPulseWidth*|
|WaveNoise   |128  |Hiss, for drums, explosions and wind      |

Waveforms can be added together (*WaveTriangle + WaveSaw*). The SID then
combines them, which gives quieter, thinner sounds that differ between
the 6581 and the 8580 (*SetSidMode*). Noise shouldn't be combined with
the others.

The gate, ring modulation and sync stay as they were. The waveform stays
set until it is changed, through any number of notes.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### waveform

The waveform, one or more of the constants above. Only the top four bits
of its low byte are used. It is a Word so a sum of constants can be passed
without a warning.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WaveSaw);
    SetEnvelope(1, 0, 9, 0, 0);
    PlayNote(1, 4 * 12 + NoteC, 30);
End.
```
