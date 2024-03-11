# DrawChar

Draws a character on the screen.

## Declaration

    Uses Screen;

    Procedure DrawChar(col, row : Byte; ch : Char);

## Description

*DrawChar* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure draws a character on the screen in the current text color. The *col* and *row* parameters
are 1-based.  The character is a PETSCII code.  Use *DrawCharRaw* to draw a screen code instead.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    SetTextColor(2);
    DrawChar(5, 5, 'a');
End.
```
