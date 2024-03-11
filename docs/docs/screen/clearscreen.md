# ClearScreen

Clears the screen.

## Declaration

    Uses Screen;

    Procedure ClearScreen;

## Description

*ClearScreen* is a part of the screen library.  You must reference the screen library in a *Uses* statement.

This procedure clears the screen.

## Example ##

```
Program example;

Uses Screen;

Begin
    ClearScreen;
    writeln(Chr(65));  (* Writes A to the output *)
End.
```
