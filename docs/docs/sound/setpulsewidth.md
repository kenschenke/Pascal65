# SetPulseWidth

Sets the width of a voice's pulse wave.

## Declaration

    Uses Sound;

    Procedure SetPulseWidth(voice : Byte; width : Word);

## Description

*SetPulseWidth* is a part of the sound library. You must reference the
sound library in a *Uses* statement.

A pulse wave (*WavePulse*) is high for part of each cycle and low for the
rest. The width sets how much of the cycle it's high, from 0 to 4095. A
width of 2048 is a square wave, hollow like a clarinet. Narrower or wider
pulses sound thinner and more nasal. A width and 4096 minus it sound the
same, and 0 or 4095 is silent.

The width only changes a pulse wave. It stays set until it's changed. A
*PulseSweep* on the voice goes on from the new width.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### width

The pulse width, 0 to 4095. Only the low 12 bits are used.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(1, WavePulse);
    SetPulseWidth(1, 2048);         // A square wave
    SetEnvelope(1, 0, 0, 15, 6);
    PlayNote(1, 4 * 12 + NoteC, 25);
End.
```
