# Sound Library

The **Sound** library plays sounds on the MEGA65's four SID chips. You
must reference the library in a *Uses* statement.

    Uses Sound;

## Voices and SIDs

The MEGA65 has four SID chips with three voices each, for 12 voices in
all. The library numbers the voices 1 through 12 and the SIDs 1 through
4. Voice *v* is on SID `(v - 1) Div 3 + 1`:

|SID|Address|Voices    |Channel|
|---|-------|----------|-------|
|1  |$D400  |1, 2, 3   |Right  |
|2  |$D420  |4, 5, 6   |Right  |
|3  |$D440  |7, 8, 9   |Left   |
|4  |$D460  |10, 11, 12|Left   |

Settings that belong to a whole SID, such as the volume, the filter and the
chip model, take a SID number. The others take a voice number.

!!! note
    SIDs 1 and 2 play on the right channel and SIDs 3 and 4 on the left.
    That's the MEGA65's default. The library doesn't change the audio
    mixer, so a program or the user can pan them differently.

A voice or SID number out of range is ignored: a procedure does nothing
and a function returns 0.

## Playing a sound

A voice makes a sound when its *gate* is open. Before opening it, give the
voice a waveform, an envelope and a frequency:

- **Waveform.** *SetWaveform* picks triangle, sawtooth, pulse or noise.
  A pulse wave also needs a width (*SetPulseWidth*).
- **Envelope.** *SetEnvelope* sets how fast the sound rises (attack),
  falls to its sustain level (decay), the sustain level itself and how
  fast it fades after the gate closes (release).
- **Frequency.** *SetFrequency* takes the SID's frequency value, not
  hertz. The value is hertz times 17.03 on a PAL MEGA65 and times 16.40
  on an NTSC one, because the SIDs run from the video clock.

*SetGate* with True starts the attack. The sound holds at the sustain
level until *SetGate* with False starts the release.

## Timed notes

*PlayNote* and *PlayFreq* open a voice's gate and return at once. The
library closes the gate after the given number of frames, so the release
plays while the program goes on with its work. *PlayNote* takes a note
number and *PlayFreq* a SID frequency value.

    PlayNote(1, 4 * 12 + NoteA, 25);    // A4 for half a second on PAL

Times are in frames, counted by the raster interrupt: 50 a second on a
PAL MEGA65 and 60 on an NTSC one. *FrameRate* returns which. A note can be
up to 255 frames long. A note of 0 frames plays until *StopVoice* or
*StopAll* stops it.

*IsPlaying* is True from the time a note starts until its gate closes. It
goes False when the release starts, not when the sound fades out. Playing a
note on a voice that is already playing one starts the attack and the time
over.

The waveform and envelope stay as they were set, so set them before
playing a note. *SetGate* doesn't change what *IsPlaying* returns.

### Note numbers

Notes are numbered 0 (C0) to 95 (B7), 12 to an octave. The library
declares a constant for each note of an octave, so a note's number is its
octave times 12 plus its constant:

    octave := 4;
    PlayNote(1, octave * 12 + NoteA, 25);   // A4, 440 Hz

*NoteFreq* returns a note's SID frequency value for the MEGA65's video
mode, with A4 tuned to 440 Hz. A note number over 95 is ignored, and
*NoteFreq* returns 0 for it. [Notes](notes.md) lists them all.

## Effects

*Sweep*, *Vibrato*, *PulseSweep* and *FilterSweep* change a sound while
it plays: they slide a voice's frequency, swing it up and down, move its
pulse width back and forth, or slide a SID's filter cutoff. Like notes,
they return at once and the raster interrupt moves them on each frame.

    PlayFreq(1, 40000, 8);          // A laser: a high note...
    Sweep(1, 40000, 3000, 14);      // ...that falls fast

[Effects](effects.md) describes them and walks through the sounds in
`sfxdemo.pas`.

## Sequences

*PlaySequence* plays a list of notes, rests and commands on a voice, so a
tune plays under the program without its help. *SetSoundDoneCallback*
sets a procedure the library calls when a voice's timed note or sequence
ends.

    PlaySequence(1, @tune[1]);

[Sequences](sequences.md) describes the bytes of a sequence and the done
callback, and walks through `tunedemo.pas`.

## Constants

The library declares these constants:

|Constant      |Value|Used with                 |
|--------------|-----|--------------------------|
|WaveTriangle  |16   |SetWaveform               |
|WaveSaw       |32   |SetWaveform               |
|WavePulse     |64   |SetWaveform               |
|WaveNoise     |128  |SetWaveform               |
|FilterLow     |16   |SetFilter (low pass)      |
|FilterBand    |32   |SetFilter (band pass)     |
|FilterHigh    |64   |SetFilter (high pass)     |
|NoteC         |0    |Note numbers              |
|NoteCSharp    |1    |Note numbers              |
|NoteD         |2    |Note numbers              |
|NoteDSharp    |3    |Note numbers              |
|NoteE         |4    |Note numbers              |
|NoteF         |5    |Note numbers              |
|NoteFSharp    |6    |Note numbers              |
|NoteG         |7    |Note numbers              |
|NoteGSharp    |8    |Note numbers              |
|NoteA         |9    |Note numbers              |
|NoteASharp    |10   |Note numbers              |
|NoteB         |11   |Note numbers              |
|SeqRest       |96   |Sequences                 |
|SeqWave       |97   |Sequences                 |
|SeqEnvelope   |98   |Sequences                 |
|SeqTempo      |99   |Sequences                 |
|SeqPulse      |100  |Sequences                 |
|SeqLoop       |101  |Sequences                 |
|SeqEnd        |102  |Sequences                 |

Add filter modes together to combine them. *FilterLow + FilterHigh* is a
notch filter. *SetWaveform* and *SetFilter* take the waveform and mode as
a Word, so a sum of constants can be passed without a warning.

## Starting and ending

When a program that uses the library starts, the library clears all four
SIDs and sets each one's volume to 15. That also stops anything left
playing by BASIC 65. When the program ends, even with a runtime error, the
library stops every note, closes every gate and sets every volume to 0, so no tone is left
sounding.

The library adds about 3.7K to a program. If a program that uses it is
too big for the dynamic runtime ("Too big; try static"), the
`(* $StaticRuntime *)` directive links only the parts of the runtime the
program needs.

## Routines

|Routine      |Purpose                                          |
|-------------|-------------------------------------------------|
|SetSidMode   |Makes a SID act like a 6581 or an 8580           |
|SetVolume    |Sets a SID's volume, 0 to 15                     |
|SetWaveform  |Sets a voice's waveform                          |
|SetEnvelope  |Sets a voice's attack, decay, sustain and release|
|SetFrequency |Sets a voice's frequency                         |
|SetPulseWidth|Sets the width of a voice's pulse wave, 0 to 4095|
|SetGate      |Starts or releases a voice's sound               |
|SetRingMod   |Ring modulates a voice with the voice before it  |
|SetSync      |Syncs a voice to the voice before it             |
|SetFilter    |Sets a SID's filter cutoff, resonance and mode   |
|FilterVoice  |Sends a voice through its SID's filter, or not   |
|GetOsc3      |Reads the output of voice 3 of a SID             |
|GetEnv3      |Reads the envelope of voice 3 of a SID           |
|NoteFreq     |Returns the SID frequency of a note number       |
|PlayNote     |Plays a note for a number of frames              |
|PlayFreq     |Plays a SID frequency for a number of frames     |
|IsPlaying    |Returns True while a voice plays a note or sequence|
|StopVoice    |Stops a voice's note and starts its release      |
|StopAll      |Stops every voice's note                         |
|FrameRate    |Returns the frames a second, 50 or 60            |
|Sweep        |Slides a voice's frequency to another            |
|Vibrato      |Swings a voice's frequency up and down           |
|PulseSweep   |Moves a voice's pulse width back and forth       |
|FilterSweep  |Slides a SID's filter cutoff to another          |
|GetFrequency |Returns the frequency a voice is playing         |
|GetPulseWidth|Returns a voice's pulse width                    |
|GetCutoff    |Returns a SID's filter cutoff                    |
|PlaySequence |Plays a sequence of notes and commands on a voice|
|SetSoundDoneCallback|Sets a procedure called when a voice finishes|
|ClearSoundDoneCallback|Stops calling it                          |

## Example

This program plays a tone on voice 1 until a key is pressed, then lets it
fade out.

```
Program Beep;

Uses Sound;

Var
    ch : Char;

Begin
    SetWaveform(1, WavePulse);
    SetPulseWidth(1, 2048);
    SetEnvelope(1, 0, 0, 15, 9);
    SetFrequency(1, 7493);          // A4 (440 Hz) on a PAL MEGA65
    SetGate(1, True);
    Writeln('Press a key');
    ch := GetKey;
    SetGate(1, False);
End.
```

This one plays a rising scale of C major on voice 1 and prints a dot each
frame while it waits, to show the program keeps running during a note.

```
Program Scale;

Uses Sound;

Var
    scale : Array[1..8] Of Byte = (0, 2, 4, 5, 7, 9, 11, 12);
    i, octave : Byte;

Begin
    SetWaveform(1, WaveTriangle);
    SetEnvelope(1, 0, 6, 8, 6);
    octave := 4;
    For i := 1 To 8 Do Begin
        PlayNote(1, octave * 12 + scale[i], 10);
        While IsPlaying(1) Do Write('.');
        Writeln;
    End;
End.
```
