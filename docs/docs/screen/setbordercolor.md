# SetBorderColor

Sets the border color.

## Declaration

    Uses Screen;

    Procedure SetBorderColor(color : Byte);

## Description

*SetBorderColor* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure sets the border color using the standard Commodore colors 0 through 15.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    SetBorderColor(0);
End.
```
