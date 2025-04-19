# SpriteData

Sets a sprite's size

## Declaration

    Uses Sprites;

    Procedure SpriteData(number : Byte; data : ^Byte);

## Description

*SpriteData* is a part of the sprites library.  You must reference the sprites library in a *Uses* statement.

This procedure sets a sprite's pixel data.

## Parameters

### Sprite Number

The sprite number, 0 through 7.

### Data

This is a pointer to the sprites pixel data.

## Example

```
Program example;

Uses Sprites;

Var
    data : Array[1..63] Of Byte;

Begin
    SpriteData(0, @data[1]);
End.
```
