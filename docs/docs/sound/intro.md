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

Add filter modes together to combine them. *FilterLow + FilterHigh* is a
notch filter. *SetWaveform* and *SetFilter* take the waveform and mode as
a Word, so a sum of constants can be passed without a warning.

## Starting and ending

When a program that uses the library starts, the library clears all four
SIDs and sets each one's volume to 15. That also stops anything left
playing by BASIC 65. When the program ends, even with a runtime error, the
library closes every gate and sets every volume to 0, so no tone is left
sounding.

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
