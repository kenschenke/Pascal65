# SpritePos

Sets the screen position for a sprite.

## Declaration

    Uses Sprites;

    Procedure SpritePos(number : Byte; x : Word; y : Byte);

## Description

*SpritePos* is a part of the sprites library.  You must reference the sprites library in a *Uses* statement.

This procedure sets the screen position for a sprite.

## Parameters

### Sprite Number

The sprite number, 0 through 7.

### X

The X coordinate for the sprite position.

### Y

The Y coordinate for the sprite position.

## Example

```
Program example;

Uses Sprites;

Begin
    SpritePos(0, 100, 110);
End.
```
