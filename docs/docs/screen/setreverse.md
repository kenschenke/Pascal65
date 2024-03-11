# SetReverse

Sets character drawing mode.

## Declaration

    Uses Screen;

    Procedure SetReverse(reverse : Boolean);

## Description

*SetReverse* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure sets the current drawing mode for future calls to *DrawChar* and *DrawText*. *DrawCharRaw*
and *DrawTextRaw* are not affected because the high bit of screen codes controls reverse.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    SetReverse(true);
End.
```
