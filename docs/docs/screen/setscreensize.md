# SetScreenSize

Sets the screen size.

## Declaration

    Uses Screen;

    Procedure SetScreenSize(cols, rows : Byte);

## Description

*SetScreenSize* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure sets the screen size. Supported screen sizes are 80x25, 80x50, and 40x25.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    SetScreenSize(40, 25);
End.
```
