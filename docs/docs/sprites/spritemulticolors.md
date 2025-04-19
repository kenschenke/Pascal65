# SpriteMultiColors

Configures a sprite.

## Declaration

    Uses Sprites;

    Procedure SpriteMultiColors(color1, color2 : Byte);

## Description

*SpriteMultiColors* is a part of the sprites library.  You must reference the sprites library in a *Uses* statement.

This procedure sets the two colors for multi-color sprites. All multi-color sprites share
these two colors. See pages 135 and 136 in the *Commodore 64 Programmer's Reference Guide*
for more information.

## Parameters

### Color1 and Color2

The colors for all multi-color sprites. The color number is 0 through 15.

## Example

```
Program example;

Uses Sprites;

Var
    x : Word;
    y : Byte;

Begin
    SpriteMultiColors(3, 5);
End.
```
