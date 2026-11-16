# SetVolume

Sets a SID's volume.

## Declaration

    Uses Sound;

    Procedure SetVolume(sid, volume : Byte);

## Description

*SetVolume* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

This procedure sets the volume of all three voices of a SID. The library
sets every SID's volume to 15 when a program starts and to 0 when it
ends. The filter mode set by *SetFilter* isn't changed.

SIDs 1 and 2 play on the right channel and SIDs 3 and 4 on the left (see
[Introduction](intro.md)), so turning one SID up as another goes down
moves a sound from side to side. `stereodemo.pas`, on the compiler disk,
does this.

## Parameters

### sid

The SID number, 1 to 4. A bad number is ignored.

### volume

The volume, 0 (silent) to 15 (loudest). Only the low four bits are used.

## Example

```
Program example;

Uses Sound;

Begin
    SetVolume(1, 8);            // SID 1 at about half volume
End.
```
