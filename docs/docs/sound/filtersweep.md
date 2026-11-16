# FilterSweep

Slides a SID's filter cutoff to another.

## Declaration

    Uses Sound;

    Procedure FilterSweep(sid : Byte; toCutoff : Word; frames : Byte);

## Description

*FilterSweep* is a part of the sound library. You must reference the
sound library in a *Uses* statement.

This procedure moves a SID's filter cutoff from where it is to
*toCutoff* over *frames* frames, like *Sweep* does a voice's frequency,
and returns at once. The last frame sets *toCutoff* exactly.

The filter changes only the voices sent through it (*FilterVoice*). Set
its resonance and mode with *SetFilter* first, then sweep it. *SetFilter*
ends a filter sweep, and so does *StopAll*. *StopVoice* doesn't, because
the filter belongs to the whole SID.

[Effects](effects.md) has more about the effects and how they combine.

## Parameters

### sid

The SID number, 1 to 4. A bad number is ignored.

### toCutoff

The cutoff to end on, 0 to 2047. Only the low 11 bits are used.

### frames

How long the sweep takes, 1 to 255 frames. 0 sets the cutoff at once.

## Example

```
Program example;

Uses Sound;

Begin
    SetWaveform(2, WaveNoise);
    SetEnvelope(2, 0, 0, 15, 11);
    FilterVoice(2, True);
    SetFilter(1, 2047, 10, FilterLow);
    PlayFreq(2, 3000, 6);           // An explosion
    FilterSweep(1, 40, 75);
End.
```
