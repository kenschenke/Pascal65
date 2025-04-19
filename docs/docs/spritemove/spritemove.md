# SpriteMove

Animates a sprite.

## Declaration

    Uses SpriteMove;

    Procedure SpriteMove(sprite : Byte; x0 : Word; y0 : Byte;
        x1 : Word; y1, speed : Byte; stopAtTarget : Boolean);

## Description

*SpriteMove* is a part of the spritemove library.  You must reference the spritemove library in a *Uses* statement.

This procedure moves a sprite in a straight line between two points. The sprite is moved
each video frame, according to the desired speed. A speed of 1 moves the sprite 1 pixel
per video frame. A speed of 2 moves the sprite 2 pixels, and so on.

## Parameters

### Sprite Number

### x0, y0

The starting position for the sprite.

### x1, y1

The ending position for the sprite.

### StopAtTarget

If *True*, the sprite stops moving when it reaches the x1 and y1. If *False*, the sprites
continues moving. If it reaches the end of the screen it wraps around to the opposite edge.

## Example

```
Program example;

Uses Sprites;

Begin
    SpriteMove(0, 10, 10, 30, 50, True);
End.
```
