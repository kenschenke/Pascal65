# DrawText

Draws a text string on the screen.

## Declaration

    Uses Screen;

    Procedure DrawText(col, row : Byte; text : String);

## Description

*DrawText* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure draws a text string on the screen in the current text color. The *col* and *row* parameters
are 1-based.  The string is PETSCII characters.  Use *DrawTextRaw* to draw with screen codes instead.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    SetTextColor(2);
    DrawText(5, 5, 'Hello');
End.
```
