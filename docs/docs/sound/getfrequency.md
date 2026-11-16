# GetFrequency

Returns the frequency a voice is playing.

## Declaration

    Uses Sound;

    Function GetFrequency(voice : Byte) : Word;

## Description

*GetFrequency* is a part of the sound library. You must reference the
sound library in a *Uses* statement.

The SID's registers can't be read back, so the library keeps what it
writes to them. This function returns the SID frequency value last
written for the voice, with its *Sweep* and *Vibrato*. A program can use
it to follow an effect or a sequence, for example to show the note a
sequence is playing (`tunedemo.pas` does).

## Parameters

### voice

The voice number, 1 to 12. A bad number returns 0.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WaveTriangle);
    PlayFreq(1, 2000, 50);
    Sweep(1, 2000, 9000, 50);
    While IsPlaying(1) Do Writeln(GetFrequency(1));
End.
```
