# SetSoundDoneCallback

Sets a procedure called when a voice finishes.

## Declaration

    Uses Sound;

    Type
        SoundDoneCb = Procedure(voice : Byte);

    Procedure SetSoundDoneCallback(callback : SoundDoneCb);

## Description

*SetSoundDoneCallback* is a part of the sound library. You must reference
the sound library in a *Uses* statement.

This procedure sets a procedure the library calls when a voice finishes:
when a timed note's gate closes (*PlayNote* or *PlayFreq* with a number
of frames) or a sequence ends (*PlaySequence*). It is called once for
each voice that finishes, even if several finish in the same frame.
*StopVoice* and *StopAll* don't call it. *ClearSoundDoneCallback* stops
the calls. Setting another callback replaces the first.

## Parameters

### callback

A pointer to the procedure. Its parameter is the number of the voice that
finished, 1 to 12.

The procedure runs in the raster interrupt, which has stopped the program
wherever it was. It must be declared at the program's outer level, not
inside another procedure or function. Keep it short and don't wait in it:
the next frame's sounds wait until it returns. It can change global
variables and call the Sound library's routines, such as *PlayNote* to
play the next sound. It must not write to the screen or a file, read the
keyboard, or work with strings.

## Example

```
Program example;

Uses Sound;

Var
    done : Boolean;

Procedure SoundDone(voice : Byte);
Begin
    If voice = 1 Then done := True;
End;

Begin
    done := False;
    SetSoundDoneCallback(@SoundDone);
    SetWaveform(1, WaveTriangle);
    PlayNote(1, 4 * 12 + NoteC, 50);
    While Not done Do Begin
        // The program's own work
    End;
    ClearSoundDoneCallback;
End.
```
