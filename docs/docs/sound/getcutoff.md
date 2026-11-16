# GetCutoff

Returns a SID's filter cutoff.

## Declaration

    Uses Sound;

    Function GetCutoff(sid : Byte) : Word;

## Description

*GetCutoff* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

The SID's registers can't be read back, so the library keeps what it
writes to them. This function returns the SID's filter cutoff, 0 to 2047,
as *SetFilter* set it or a *FilterSweep* has moved it.

## Parameters

### sid

The SID number, 1 to 4. A bad number returns 0.

## Example

```
Program example;

Uses Sound;

Begin
    SetFilter(1, 2047, 0, FilterLow);
    FilterSweep(1, 40, 75);
    Writeln(GetCutoff(1));
End.
```
