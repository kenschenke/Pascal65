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

The procedure runs in the interrupt, which has stopped the program
wherever it was. It must be declared at the program's outer level, not
inside another procedure or function. Keep it short and don't wait in it.
It can change the program's variables and do arithmetic, but it must not
write to the screen or a file, read the keyboard, or work with strings.

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
