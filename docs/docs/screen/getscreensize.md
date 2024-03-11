# GetScreenSize

Gets the current screen size.

## Declaration

    Uses Screen;

    Procedure GetScreenSize(Var cols, rows : Byte);

## Description

*GetScreenSize* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure gets the current screen size.

## Example ##

```
Program example;

Uses Screen;

Var
    cols, rows : Byte;

Begin
    ClearScreen;
    GetScreenSize(cols, rows);
    Writeln('Your screen is ', cols, ' x ', rows);
End.
```
