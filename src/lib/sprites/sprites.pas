(*
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Sprites Library
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Unit Sprites;

Interface

Type
    SpriteCollisionCb = Procedure(Sprites : Byte; IsSToS : Boolean);

Procedure GetSpritePos(number : Byte; Var x : Word; Var y : Byte);
Procedure Sprite(number, color : Byte; enabled, isMultiColor : Boolean);
Procedure SpriteMultiColors(color1, color2 : Byte);
Procedure SpritePos(number : Byte; x : Word; y : Byte);
Procedure SpriteSize(number : Byte; isDoubleX, isDoubleY : Boolean);
Procedure SpriteData(number : Byte; data : ^Byte);
Procedure SetCollisionCallback(callback : SpriteCollisionCb);

Implementation Library

End.
