# SpriteSize

Sets a sprite's size

## Declaration

    Uses Sprites;

    Procedure SpriteSize(number : Byte; isDoubleX, isDoubleY : Boolean);

## Description

*SpriteSize* is a part of the sprites library.  You must reference the sprites library in a *Uses* statement.

This procedure sets a sprite's size as normal or double-sized.

## Parameters

### Sprite Number

The sprite number, 0 through 7.

### isDoubleX

*True* if the sprite's size is doubled horizontally.

### isDoubleY

*True* if the sprite's size is doubled vertically.

## Example

```
Program example;

Uses Sprites;

Begin
    SpriteSize(0, True, True);
End.
```
