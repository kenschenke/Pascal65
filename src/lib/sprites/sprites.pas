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

Procedure Sprite(number : Byte; enabled : Boolean);
Procedure SpriteColor(number, color : Byte);
Procedure SpriteMultiColor(number : Byte; isMultiColor : Boolean);
Procedure SpritePos(number : Byte; x : Integer; y : Byte);
Procedure SpriteSize(number : Byte; isDoubleX, isDoubleY : Boolean);
Procedure SpriteMove(number : Byte; x0 : Integer; y0 : Byte;
    x1 : Integer; y1, speed : Byte; stopAtTarget : Boolean);
Procedure SpriteMoveRel(number : Byte; xRel : Integer; yRel : Byte);
Procedure SpriteData(number : Byte; data : ^Byte);

Implementation Library

End.
