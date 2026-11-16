# GetPulseWidth

Returns a voice's pulse width.

## Declaration

    Uses Sound;

    Function GetPulseWidth(voice : Byte) : Word;

## Description

*GetPulseWidth* is a part of the sound library. You must reference the
sound library in a *Uses* statement.

The SID's registers can't be read back, so the library keeps what it
writes to them. This function returns the voice's pulse width, 0 to 4095,
as *SetPulseWidth* set it or a *PulseSweep* has moved it.

## Parameters

### voice

The voice number, 1 to 12. A bad number returns 0.

## Example

```
Program example;

Uses Sound;

Begin
    SetPulseWidth(1, 512);
    PulseSweep(1, 24);
    Writeln(GetPulseWidth(1));
End.
```
