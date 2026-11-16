# GetEnv3

Reads the envelope of voice 3 of a SID.

## Declaration

    Uses Sound;

    Function GetEnv3(sid : Byte) : Byte;

## Description

*GetEnv3* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

Each SID lets the program read the level of its third voice's envelope
(*SetEnvelope*) as it plays, from 0 to 255. That's voice 3, 6, 9 or 12
for SIDs 1 to 4. A program can use it to show a sound's level or to
drive another setting, such as a filter cutoff, from the envelope.

!!! note
    The xmega65 emulator doesn't model this register. It returns noise
    for SIDs 1 and 2 and 255 for SIDs 3 and 4, whatever the voices do.

## Parameters

### sid

The SID number, 1 to 4. A bad number returns 0.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(3, WaveTriangle);
    SetEnvelope(3, 10, 0, 15, 10);  // A slow attack
    PlayNote(3, 4 * 12 + NoteC, 100);
    While IsPlaying(3) Do Writeln(GetEnv3(1));
End.
```
