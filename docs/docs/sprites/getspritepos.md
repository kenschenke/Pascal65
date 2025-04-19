# GetSpritePos

Retrieves a sprite's current position.

## Declaration

    Uses Sprites;

    Procedure GetSpritePos(number : Byte; Var x : Word; Var y : Byte);

## Description

*GetSpritePos* is a part of the sprites library.  You must reference the sprites library in a *Uses* statement.

This procedure retrieves a sprite's current position on the screen.

The first parameter is the sprite number, 0 through 7. The second and third parameters are
references to variables that will contain the X and Y position of the sprite when the
procedure returns.

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
