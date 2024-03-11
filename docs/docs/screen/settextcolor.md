# SetTextColor

Sets the current text color.

## Declaration

    Uses Screen;

    Procedure SetTextColor(color : Byte);

## Description

*SetTextColor* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure sets the current text color using the standard Commodore colors 0 through 15. Future calls to
*DrawChar*, *DrawCharRaw*, *DrawText*, and *DrawTextRaw* will use the new text color.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    SetTextColor(0);
End.
```
