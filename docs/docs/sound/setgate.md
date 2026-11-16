# SetGate

Starts or releases a voice's sound.

## Declaration

    Uses Sound;

    Procedure SetGate(voice : Byte; on : Boolean);

## Description

*SetGate* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

Opening a voice's gate starts its envelope: the attack, then the decay to
the sustain level, where it holds. Closing the gate starts the release
(see *SetEnvelope*). The waveform, ring modulation and sync stay as they
were.

*SetGate* plays a sound for as long as the program wants. *PlayNote* and
*PlayFreq* open the gate and let the library close it after a number of
frames. *SetGate* doesn't change what *IsPlaying* returns, and a timed
note still closes the gate when it ends.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### on

*True* opens the gate, *False* closes it.

## Example

```
Program example;

Uses Sound;

Var
    ch : Char;

Begin
    SetWaveform(1, WaveSaw);
    SetEnvelope(1, 0, 0, 15, 9);
    SetFrequency(1, NoteFreq(3 * 12 + NoteG));
    SetGate(1, True);
    ch := GetKey;                   // Plays until a key is pressed
    SetGate(1, False);              // Then fades out
End.
```
