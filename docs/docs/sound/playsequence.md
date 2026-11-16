# PlaySequence

Plays a sequence of notes and commands on a voice.

## Declaration

    Uses Sound;

    Procedure PlaySequence(voice : Byte; data : ^Byte);

## Description

*PlaySequence* is a part of the sound library. You must reference the
sound library in a *Uses* statement.

A sequence is a list of bytes: notes with their lengths, rests, and
commands that set the waveform, envelope, tempo and pulse width, loop or
end. This procedure starts one on a voice and returns at once. The raster
interrupt plays it, so a tune plays while the program goes on with its
work. Each voice can play a sequence of its own.

*IsPlaying* is True until the sequence ends. When it ends, the done
callback (*SetSoundDoneCallback*) is called, if one is set. A sequence
that loops plays until *StopVoice* or *StopAll* stops it. *PlayNote*,
*PlayFreq* and another *PlaySequence* on the voice end it too.

[Sequences](sequences.md) describes the bytes and has examples.

!!! warning
    The library reads the sequence from the program's memory while it
    plays. The array must stay in memory until the sequence ends or the
    voice is stopped. A global variable is safe. A local variable of a
    procedure is freed when the procedure returns.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### data

A pointer to the first byte of the sequence, usually the first element of
an *Array Of Byte*. *Nil* is ignored.

## Example

```
Program example;

Uses Sound;

Var
    // SeqTempo 3, SeqWave triangle, then C4 E4 G4 and SeqEnd
    arpeggio : Array[1..11] Of Byte = (99, 3, 97, 16,
        48, 4, 52, 4, 55, 8, 102);

Begin
    PlaySequence(1, @arpeggio[1]);
    While IsPlaying(1) Do Begin End;
End.
```
