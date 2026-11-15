# Effects

The library's effects change a sound while it plays. Each one is set up
by a call that returns at once. The raster interrupt then moves the
effect on once a frame, while the program goes on with its work.

|Routine    |What it moves                                 |
|-----------|----------------------------------------------|
|Sweep      |A voice's frequency, in a straight line       |
|Vibrato    |A voice's frequency, up and down around a note|
|PulseSweep |A voice's pulse width, back and forth         |
|FilterSweep|A SID's filter cutoff, in a straight line     |

Every voice can run all three of its effects at once, and each SID a
filter sweep. Times are in frames, 50 a second on PAL and 60 on NTSC
(*FrameRate*).

## Sweep

    Procedure Sweep(voice : Byte; fromFreq, toFreq : Word; frames : Byte);

*Sweep* sets the voice's frequency to *fromFreq* and moves it to *toFreq*
over *frames* frames, by the same amount each frame. The last frame sets
*toFreq* exactly, and the frequency stays there. A sweep of 0 frames sets
*toFreq* at once.

*Sweep* doesn't open the gate. Start the note first, then the sweep:

    PlayFreq(1, 40000, 8);
    Sweep(1, 40000, 3000, 14);

A note (*PlayNote* or *PlayFreq*) and *SetFrequency* end a sweep, so a
sweep started before a note would be lost. A sweep goes on after a timed
note ends, through its release. That's how the laser above keeps falling
as it fades.

## Vibrato

    Procedure Vibrato(voice, depth, frames : Byte);

*Vibrato* swings the voice's frequency above and below its note in a
triangle wave. It takes *frames* frames to swing from the top to the
bottom, so a whole swing, up and back, takes twice that. *depth* sets how
far it swings: the frequency goes *depth* / 1024 of the note's frequency
each way.

|depth|Swing each way|About                    |
|-----|--------------|-------------------------|
|5    |0.5%          |8 cents, a gentle vibrato|
|10   |1%            |17 cents                 |
|60   |6%            |1 semitone               |
|255  |25%           |4 semitones up, 5 down   |

A depth or frames of 0 turns the vibrato off and puts the note's
frequency back.

The vibrato stays on from note to note: *PlayNote*, *PlayFreq* and
*SetFrequency* start it over from the new frequency. So a voice can be
given a vibrato once, like its waveform. A vibrato and a sweep on one
voice add up, but the size of the swing is worked out from the frequency
when the vibrato or the note starts, not as the sweep moves it.

The frequency never goes over 65,535, the highest a SID takes.

## PulseSweep

    Procedure PulseSweep(voice : Byte; stepSize : Integer);

*PulseSweep* adds *stepSize* to the voice's pulse width each frame,
starting from the width *SetPulseWidth* gave it. When the width would go
past 3968 or under 128, it stops there and turns around, so it moves back
and forth until it's turned off. A negative *stepSize* starts it falling.
A *stepSize* of 0 turns it off and leaves the width where it is.

Sweeping the pulse width (pulse width modulation) makes a pulse wave
shimmer, like a chorus of voices. Only a pulse wave (*WavePulse*) has a
width, so it has no effect on the others. A width and 4096 minus it sound
the same, so the sweep doesn't go near 0 or 4095, where the pulse goes
silent.

*SetPulseWidth* during a sweep moves the width, and the sweep goes on
from there.

## FilterSweep

    Procedure FilterSweep(sid : Byte; toCutoff : Word; frames : Byte);

*FilterSweep* moves a SID's filter cutoff from where it is to *toCutoff*
over *frames* frames, like *Sweep*. The cutoff is 0 to 2047; a larger
*toCutoff* keeps only its low 11 bits, as *SetFilter* does. A sweep of 0
frames sets the cutoff at once. *SetFilter* ends a filter sweep.

The filter changes only the voices sent through it (*FilterVoice*). Set
its resonance and mode with *SetFilter* first, then sweep it.

## Stopping effects

*StopVoice* ends every effect on the voice as well as its note.
*StopAll* does that for every voice and also ends the filter sweeps. The
frequency stays where a sweep left it, without the vibrato's swing, and
the pulse width and cutoff stay where they are.

## Reading the values

The SID's registers can't be read back, so the library keeps what it
writes to them:

    Function GetFrequency(voice : Byte) : Word;
    Function GetPulseWidth(voice : Byte) : Word;
    Function GetCutoff(sid : Byte) : Word;

*GetFrequency* returns the frequency the voice is playing, with its sweep
and vibrato. *GetPulseWidth* and *GetCutoff* return the pulse width and
the filter cutoff. They return 0 for a bad voice or SID number.

## Sound effects

`sfxdemo.pas`, on the compiler disk, plays each of these on a key. Every
effect has a voice of its own, so they can sound together. The envelopes
are set once at the start, because a voice keeps its waveform and
envelope.

### Laser

A narrow pulse (*SetPulseWidth* 1024) with no attack and a short release
(6). The note starts high and falls fast:

    PlayFreq(1, 40000, 8);
    Sweep(1, 40000, 3000, 14);

The sweep is longer than the note, so the pitch is still falling as it
fades.

### Explosion

Noise, routed through SID 1's low pass filter, with a long release (11).
The filter opens all the way and closes over a second and a half (on
PAL), so the noise turns from a crash into a rumble. A falling noise
frequency makes the rumble deeper:

    SetFilter(1, 2047, 10, FilterLow);
    PlayFreq(2, 3000, 6);
    Sweep(2, 3000, 600, 75);
    FilterSweep(1, 40, 75);

### Coin

Two quick square wave notes, B5 and then E6. The second note has to wait
for the first, but the program shouldn't, so the main loop starts it when
*IsPlaying* says the first has ended:

    PlayNote(3, 5 * 12 + NoteB, 4);
    coinWaiting := True;
    ...
    If coinWaiting And Not IsPlaying(3) Then Begin
        PlayNote(3, 6 * 12 + NoteE, 12);
        coinWaiting := False;
    End;

### Jump

A triangle wave rising, with a short release (4):

    PlayFreq(4, 2000, 12);
    Sweep(4, 2000, 9000, 14);

### Siren

A sawtooth with the widest, slowest vibrato. The note swings about four
semitones each way, once every 1.2 seconds on PAL, until it's stopped:

    PlayNote(5, 5 * 12 + NoteA, 0);
    Vibrato(5, 255, 30);

### Alarm

A square wave with a fast, wide vibrato that warbles it:

    PlayNote(6, 6 * 12 + NoteC, 0);
    Vibrato(6, 120, 3);

### Engine

A low sawtooth (A1) with a fast, shallow vibrato, and a slow attack (6)
and release (8) so it starts and stops like a motor:

    PlayNote(7, 1 * 12 + NoteA, 0);
    Vibrato(7, 30, 2);

### Pulse width pad

A pulse that starts narrow (*SetPulseWidth* 512), with a slow attack (8)
and release (10). The pulse sweep keeps moving through the release:

    PlayNote(8, 3 * 12 + NoteC, 100);
    PulseSweep(8, 24);
