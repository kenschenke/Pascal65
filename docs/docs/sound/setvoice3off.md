# SetVoice3Off

Silences voice 3 of a SID while it goes on playing.

## Declaration

    Uses Sound;

    Procedure SetVoice3Off(sid : Byte; off : Boolean);

## Description

*SetVoice3Off* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

Each SID can cut its third voice (voice 3, 6, 9 or 12 for SIDs 1 to 4) off
from its output. The voice goes on running: its gate, envelope and
oscillator work as before, so *GetOsc3* and *GetEnv3* still follow it. A
program can play notes on the voice to drive another setting from it, such
as a filter cutoff or another voice's frequency, without hearing it.

This is not the same as *StopVoice*, which closes the gate. The voice is
heard as it fades through its release, and its envelope, which *GetEnv3*
reads, falls to 0.

The setting stays until it is changed. *SetVolume* and *SetFilter* don't
change it. When the program starts and ends, it is off.

!!! note
    The SID only cuts voice 3 off when the voice isn't sent through the
    filter. If *FilterVoice* sends it through, it is heard through the
    filter whatever *SetVoice3Off* says.

## Parameters

### sid

The SID number, 1 to 4. A bad number is ignored.

### off

*True* silences voice 3, *False* lets it be heard again.

## Example

```
Program example;

Uses Sound;

Var
    i : Integer;

Begin
    // Voice 3 is a slow, silent triangle wave
    SetWaveform(3, WaveTriangle);
    SetFrequency(3, 20);
    SetEnvelope(3, 0, 0, 15, 0);
    SetVoice3Off(1, True);
    SetGate(3, True);

    // Voice 1 follows it
    SetWaveform(1, WaveSaw);
    SetEnvelope(1, 0, 0, 15, 0);
    SetGate(1, True);
    For i := 1 To 5000 Do SetFrequency(1, 5000 + GetOsc3(1) * 10);
    SetGate(1, False);
End.
```
