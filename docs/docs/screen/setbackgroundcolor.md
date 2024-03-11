# SetBackgroundColor

Sets the background color.

## Declaration

    Uses Screen;

    Procedure SetBackgroundColor(color : Byte);

## Description

*SetBackgroundColor* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure sets the background color using the standard Commodore colors 0 through 15.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    SetBackgroundColor(0);
End.
```
