# SetSidMode

Makes a SID act like a 6581 or an 8580.

## Declaration

    Uses Sound;

    Procedure SetSidMode(sid : Byte; is8580 : Boolean);

## Description

*SetSidMode* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

The MEGA65's SIDs can sound like either of the two SID chips Commodore
made: the 6581 of the first Commodore 64s or the 8580 of later ones. The
two differ mostly in their filters and in how waveforms combine. This
procedure picks one for a SID. The other three SIDs keep their setting.

## Parameters

### sid

The SID number, 1 to 4. A bad number is ignored.

### is8580

*True* for an 8580, *False* for a 6581.

## Example

```
Program example;

Uses Sound;

Begin
    SetSidMode(1, True);        // SID 1 sounds like an 8580
    SetSidMode(3, False);       // SID 3 like a 6581
End.
```
