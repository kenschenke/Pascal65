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
procedure. **Nil** can be passed as a parameter to stop callbacks to the
previous procedure.

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
