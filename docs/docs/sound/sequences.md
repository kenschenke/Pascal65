# Sequences

A sequence is a list of notes and commands that a voice plays by itself.
*PlaySequence* starts one and returns at once. The raster interrupt moves
it on each frame, so a tune plays while the program goes on with its
work. Each voice can play a sequence of its own, so three voices on one
SID can play a melody, a bass line and chords together.

    PlaySequence(1, @tune[1]);

## Declarations

    Uses Sound;

    Procedure PlaySequence(voice : Byte; data : ^Byte);

*voice* is 1 to 12. *data* points to the first byte of the sequence,
usually the first element of an *Array Of Byte*. A bad voice number or a
*Nil* pointer is ignored.

!!! warning
    The library reads the sequence from the program's memory while it
    plays. The array must stay in memory until the sequence ends or the
    voice is stopped. A global variable is safe. A local variable of a
    procedure is freed when the procedure returns, and the voice then
    plays whatever is left in that memory.

## The bytes

A sequence is a stream of bytes. A byte of 0 to 95 is a note, and the
byte after it is its length. A byte of 96 or more is a command, and some
commands are followed by the bytes they need:

|Byte|Constant   |Followed by                         |What it does                         |
|----|-----------|------------------------------------|-------------------------------------|
|0-95|           |Length                              |Plays a note                         |
|96  |SeqRest    |Length                              |Closes the gate and waits            |
|97  |SeqWave    |Waveform                            |Sets the waveform (*SetWaveform*)    |
|98  |SeqEnvelope|`attack*16+decay`, `sustain*16+release`|Sets the envelope (*SetEnvelope*)|
|99  |SeqTempo   |Frames                              |Sets the frames in a tick            |
|100 |SeqPulse   |Low byte, high byte                 |Sets the pulse width (*SetPulseWidth*)|
|101 |SeqLoop    |                                    |Goes back to the first byte          |
|102 |SeqEnd     |                                    |Ends the sequence                    |

Notes are numbered as for *PlayNote*: octave times 12 plus the note's
constant, so 57 is A4 (see [Notes](notes.md)).

A note sets the voice's frequency and opens its gate, closing it first if
it was open, so each note's attack starts over. The gate stays open until
the next note or rest. A rest closes the gate, so the last note's release
plays during the rest.

The commands take effect at once: the library reads on to the next note
or rest in the same frame. The waveform, envelope and pulse width stay set
after the sequence ends, as if the program had set them.

### Lengths and tempo

Lengths are in ticks. A tick is one frame to start with, and *SeqTempo*
changes it for the notes after it. With a tempo of 3, a length of 4 is 12
frames. A length or tempo of 0 is taken as 1. A frame is a 50th of a
second on a PAL MEGA65 and a 60th on an NTSC one, so a tune plays a little
faster on NTSC.

A common choice is a tick for a sixteenth note. At a tempo of 3 on PAL:

|Length|Note      |Seconds|
|------|----------|-------|
|1     |Sixteenth |0.06   |
|2     |Eighth    |0.12   |
|4     |Quarter   |0.24   |
|8     |Half      |0.48   |
|16    |Whole     |0.96   |

### Ending

At *SeqEnd* the voice closes its gate and stops playing, as at the end of
a timed note: *IsPlaying* turns False and the done callback is called (see
below). A byte over 102 ends the sequence too.

*SeqLoop* starts the sequence over from its first byte, and it plays
until *StopVoice* or *StopAll* stops it. The commands at the start run
again each time. A loop with no note or rest in it ends the sequence.

## Playing and stopping

*IsPlaying* is True from the time *PlaySequence* starts a sequence until
it ends, even during a rest.

*PlayNote*, *PlayFreq* and another *PlaySequence* on the same voice end
the sequence and play in its place. *StopVoice* and *StopAll* end it and
start the release. Neither calls the done callback.

A sequence keeps the voice's vibrato and pulse sweep going from note to
note, as *PlayNote* does. Each note ends a frequency sweep.

## Writing sequences in a program

An array's initial values must be number literals, so a sequence written
as the initial value of an array uses the numbers, not the constants:

```
Var
    // SeqTempo 3, SeqWave triangle, then C4 E4 G4 and SeqEnd
    arpeggio : Array[1..11] Of Byte = (99, 3, 97, 16,
        48, 4, 52, 4, 55, 8, 102);
```

The constants can be used when a program builds a sequence in code:

```
Var
    tune : Array[1..7] Of Byte;

Begin
    tune[1] := SeqWave;
    tune[2] := WavePulse;
    tune[3] := 4 * 12 + NoteA;      // A4 for 8 ticks
    tune[4] := 8;
    tune[5] := SeqRest;
    tune[6] := 8;
    tune[7] := SeqLoop;
    SetPulseWidth(1, 2048);
    PlaySequence(1, @tune[1]);
```

## The done callback

    Type
        SoundDoneCb = Procedure(voice : Byte);

    Procedure SetSoundDoneCallback(callback : SoundDoneCb);
    Procedure ClearSoundDoneCallback;

*SetSoundDoneCallback* sets a procedure the library calls when a voice
finishes: when a timed note's gate closes (*PlayNote* or *PlayFreq* with a
number of frames) or a sequence ends. *voice* is the voice's number, 1 to
12. It is called once for each voice that finishes, even if several finish
in the same frame. *StopVoice* and *StopAll* don't call it.
*ClearSoundDoneCallback* stops the calls.

```
Procedure SoundDone(voice : Byte);
Begin
    If voice = 1 Then tuneOver := True;
End;

Begin
    SetSoundDoneCallback(@SoundDone);
    PlaySequence(1, @tune[1]);
    While Not tuneOver Do Begin
        // The program's own work
    End;
End.
```

!!! warning
    The callback runs in the raster interrupt, which has stopped the
    program wherever it was. Keep it short and don't wait in it: the next
    frame's sounds wait until it returns. It can change global variables
    and call the Sound library's routines, such as *PlayNote* to play the
    next sound. It must not write to the screen or a file, read the
    keyboard, or work with strings, because the program may have been
    stopped in the middle of doing the same.

The callback must be declared at the program's outer level, not inside
another procedure or function.

## Example

`tunedemo.pas`, on the compiler's disk, plays a short tune on voices 1,
2 and 3 and prints the melody's notes as they play. It starts the three
sequences right after the raster goes back to the top of the screen, so
they all start between two interrupts and stay together. Their lengths add up
to the same number of ticks, so they loop together too.
