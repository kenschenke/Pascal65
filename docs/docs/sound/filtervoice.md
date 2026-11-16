# FilterVoice

Sends a voice through its SID's filter, or not.

## Declaration

    Uses Sound;

    Procedure FilterVoice(voice : Byte; on : Boolean);

## Description

*FilterVoice* is a part of the sound library. You must reference the sound
library in a *Uses* statement.

A voice sent through the filter is changed by its SID's filter settings
(*SetFilter*). The SID's other voices aren't, unless they are sent too.
Voice *v* is on SID `(v - 1) Div 3 + 1`, so voices 1 to 3 share SID 1's
filter.

## Parameters

### voice

The voice number, 1 to 12. A bad number is ignored.

### on

*True* sends the voice through the filter, *False* takes it out.

## Example

```
Program example;

Uses Sound;

Begin
    SetFilter(1, 300, 4, FilterLow);
    FilterVoice(2, True);           // Muffles voice 2 only
End.
```
