# SetEnvelope

Sets a voice's attack, decay, sustain and release.

## Declaration

    Uses Sound;

    Procedure SetEnvelope(voice, attack, decay, sustain, release : Byte);

## Description

*SetEnvelope* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

The envelope shapes a voice's volume over the life of a note. When the
gate opens, the volume rises from 0 to the top over the *attack* time,
then falls to the *sustain* level over the *decay* time. It stays there
while the gate is open. When the gate closes it falls to 0 over the
*release* time.

Each value is 0 to 15. Sustain is a level, 0 silent and 15 the top. The
others are times:

|Value|Attack|Decay or release|
|-----|------|----------------|
|0    |2 ms  |6 ms            |
|1    |8 ms  |24 ms           |
|2    |16 ms |48 ms           |
|3    |24 ms |72 ms           |
|4    |38 ms |114 ms          |
|5    |56 ms |168 ms          |
|6    |68 ms |204 ms          |
|7    |80 ms |240 ms          |
|8    |100 ms|300 ms          |
|9    |250 ms|750 ms          |
|10   |500 ms|1.5 s           |
|11   |800 ms|2.4 s           |
|12   |1 s   |3 s             |
|13   |3 s   |9 s             |
|14   |5 s   |15 s            |
|15   |8 s   |24 s            |

The decay and release times are for the whole range, from the top to 0.
A percussive sound, such as a plucked string or a drum, has no attack, a
decay and a sustain of 0. An organ has no attack or decay and a sustain of
15. A sound with a sustain of 0 fades out by itself even while the gate
is open.

The envelope stays set until it is changed.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### attack, decay, sustain, release

The envelope's values, 0 to 15 each. Only the low four bits are used.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WaveTriangle);
    SetEnvelope(1, 0, 9, 0, 9);     // A pluck that rings out
    PlayNote(1, 4 * 12 + NoteE, 10);
End.
```
