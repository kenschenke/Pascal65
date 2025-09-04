# GetTicks

Retrieves the value of the system timer.

## Declaration

    Uses Time;

    Function GetTicks : Cardinal;

## Description

This function retrieves the value of a high-precision system timer. The timer counts
milliseconds in elapsed time. By default, the timer is started when the computer is
turned on. The [ResetTicks](../resetticks) procedure resets the timer to zero.

Programs can use this function to calculate elapsed time.

## Example ##

```
Program example;

Uses Time;

Var
    t : Cardinal;

Begin
    Writeln(t Div 1000000, ' seconds have elapsed);
End.
```

## See Also ##

[ResetTicks](../resetticks)