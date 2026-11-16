# GetOsc3

Reads the output of voice 3 of a SID.

## Declaration

    Uses Sound;

    Function GetOsc3(sid : Byte) : Byte;

## Description

*GetOsc3* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

Each SID lets the program read the top eight bits of its third voice's
wave as it plays. That's voice 3, 6, 9 or 12 for SIDs 1 to 4. With the
noise waveform and a high frequency, the value changes all the time,
which makes it a source of random numbers. With a slow triangle or
sawtooth wave, it can move something on the screen in step with the
sound.

The voice doesn't need an open gate: its wave runs whenever it has a
waveform and a frequency.

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

Var
    i : Byte;

Begin
    SetWaveform(3, WaveNoise);
    SetFrequency(3, 65535);
    For i := 1 To 10 Do Writeln(GetOsc3(1));    // Random numbers
End.
```
