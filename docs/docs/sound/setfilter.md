# SetFilter

Sets a SID's filter cutoff, resonance and mode.

## Declaration

    Uses Sound;

    Procedure SetFilter(sid : Byte; cutoff : Word; resonance : Byte;
        mode : Word);

## Description

*SetFilter* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

Each SID has one filter. It changes the voices sent through it with
*FilterVoice*; the others play as they are. The mode picks which
frequencies it keeps:

|Constant  |Value|Keeps                                    |
|----------|-----|-----------------------------------------|
|FilterLow |16   |Frequencies below the cutoff (muffled)   |
|FilterBand|32   |Frequencies near the cutoff (thin, nasal)|
|FilterHigh|64   |Frequencies above the cutoff (tinny)     |

Modes can be added together. *FilterLow + FilterHigh* is a notch filter,
which takes out the frequencies near the cutoff. A mode of 0 keeps
nothing, so the filtered voices go silent.

The cutoff is 0 (lowest) to 2047 (highest). Resonance, 0 to 15, makes the
filter ring at the cutoff, giving it a sharper sound. The filters of the
6581 and 8580 differ, so the same settings sound different on each
(*SetSidMode*).

*SetFilter* ends a *FilterSweep* on the SID. The volume set by *SetVolume*
isn't changed.

## Parameters

### sid

The SID number, 1 to 4. A bad number is ignored.

### cutoff

The cutoff, 0 to 2047. Only the low 11 bits are used.

### resonance

The resonance, 0 to 15. Only the low four bits are used.

### mode

The filter mode, one or more of the constants above. It is a Word so a
sum of constants can be passed without a warning.

## Example

```
Program example;

Uses Sound;

Begin
    SetFilter(1, 600, 12, FilterLow);
    FilterVoice(1, True);
    SetWaveform(1, WaveSaw);
    SetEnvelope(1, 0, 0, 15, 6);
    PlayNote(1, 2 * 12 + NoteA, 50);
    FilterSweep(1, 1800, 50);       // The filter opens as it plays
End.
```
