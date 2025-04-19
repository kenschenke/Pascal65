# SetCollisionCallback

Sets a callback to handle sprite collisions.

## Declaration

    Uses Sprites;

Type
    SpriteCollisionCb = Procedure(Sprites : Byte; IsSToS : Boolean);

    Procedure SetCollisionCallback(callback : SpriteCollisionCb);

## Description

*SetCollisionCallback* is a part of the sprites library.  You must reference the sprites library in a *Uses* statement.

This procedure sets a callback to handle sprite collisions.

## Parameters

### callback

A pointer to a callback procedure. The procedure is called when the VIC chip detects
a sprite collision. The first parameter to the callback is a mask to indicate which
sprites are involved in a collision. The second parameter is *True* if the collision
is a sprite-to-sprite collision. The parameter is *False* if it is a sprite-to-data
(screen text or characters) collision.

## Example

```
Program example;

Uses Sprites;

Procedure MyCallback(Sprites : Byte; IsSpriteOnSprite : Boolean);
Begin
    // Respond to collision
End;

Begin
    SetCollisionCallback(@MyCallback);
End.
```
