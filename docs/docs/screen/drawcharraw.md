# DrawCharRaw

Draws a character on the screen.

## Declaration

    Uses Screen;

    Procedure DrawCharRaw(col, row : Byte; ch : Char);

## Description

*DrawCharRaw* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure draws a character on the screen in the current text color. The *col* and *row* parameters
are 1-based.  The character is a screen code.  Use *DrawChar* to draw a PETSCII character instead.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    SetTextColor(2);
    DrawCharRaw(5, 5, 0);  // Draws an '@'
End.
```
