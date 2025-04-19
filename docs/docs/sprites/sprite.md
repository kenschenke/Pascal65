# Sprite

Configures a sprite.

## Declaration

    Uses Sprites;

    Procedure Sprite(number, color : Byte; enabled, isMultiColor : Boolean);

## Description

*Sprite* is a part of the sprites library.  You must reference the sprites library in a *Uses* statement.

This procedure configures a sprite, enables (shows) or disables (hides) it, and sets
the color.

## Parameters

### Sprite Number

The sprite number, 0 through 7.

### Color

The sprite's color, if the sprite is configured as a single color. The color number,
is 0 through 15.

### Enabled

If *True*, the sprite is shown. If *False*, the sprite is hidden.

### IsMultiColor

If *True*, the sprite is multi-color.

## Example ##

```
Program example;

Uses Sprites;

Var
    x : Word;
    y : Byte;

Begin
    GetSpritePos(1, x, y);
End.
```
