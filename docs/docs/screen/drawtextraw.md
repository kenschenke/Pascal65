# DrawTextRaw

Draws a text string on the screen.

## Declaration

    Uses Screen;

    Procedure DrawTextRaw(col, row : Byte; text : String);

## Description

*DrawTextRaw* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure draws a text string of screen codes on the screen in the current text color. The *col* and *row* parameters
are 1-based.  The string is screen codes.  Use *DrawText* to draw with PETSCII characters instead.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    SetTextColor(2);
    DrawTextRaw(5, 5, Chr(8) + Chr(9));  // Draws "HI"
End.
```
