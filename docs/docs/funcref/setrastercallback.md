# SetRasterCallback

Sets a procedure to be called for each video frame.

## Declaration

    Type RasterCb = Procedure;
    Procedure SetRasterCallback(RasterCb);

## Description

*SetRasterCallback* sets a procedure to be called once for each video frame.
This is a common programming pattern for games. The procedure will be called
when the raster is outside the viewable frame to allow for screen updates.

A program can only have one callback set. Subsequent calls will replace the
procedure. To stop the work it does, have the procedure check a variable.

The procedure runs in the raster interrupt, which has stopped the program
wherever it was. It must be declared at the program's outer level, not
inside another procedure or function. Keep it short and don't wait in it.
It can change the program's variables and do arithmetic, but it must not
write to the screen or a file, read the keyboard, or work with strings.

## Example ##

```
Program example;

Procedure MyCallback;
Begin
    ...
End;

Begin
    SetRasterCallback(@MyCallback);
End.
```
