# ClearSoundDoneCallback

Stops calling the done callback.

## Declaration

    Uses Sound;

    Procedure ClearSoundDoneCallback;

## Description

*ClearSoundDoneCallback* is a part of the sound library. You must
reference the sound library in a *Uses* statement.

This procedure removes the procedure set by *SetSoundDoneCallback*, so
the library no longer calls it when a voice finishes. *Nil* can't be
passed to *SetSoundDoneCallback*, so this is the way to turn it off.

## Example

```
Program example;

Uses Sound;

Procedure SoundDone(voice : Byte);
Begin
End;

Begin
    SetSoundDoneCallback(@SoundDone);
    // ...
    ClearSoundDoneCallback;
End.
```
