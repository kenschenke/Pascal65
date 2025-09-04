# ResetTicks

Resets the system timer to zero.

## Declaration

    Uses Time;

    Procedure ResetTicks;

## Description

This function resets the high-precision system timer to zero. The timer counts
milliseconds in elapsed time. By default, the timer is started when the computer is
turned on. The [GetTicks](../getticks) procedure retrieves the timer value.

## Example ##

```
Program example;

Uses Time;

Var
    t : Cardinal;

Begin
    ResetTicks;
    // ... do things
    t := GetTicks;
    Writeln(t Div 1000000, ' seconds have elapsed');
End.
```

## See Also ##

[GetTicks](../getticks)
