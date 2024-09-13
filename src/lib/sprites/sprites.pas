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
Procedure SpritePos(number : Byte; x, y : Integer);
Procedure SpriteSize(number : Byte; isDoubleX, isDoubleY : Boolean);
Procedure SpriteMove(number : Byte; x0, y0, x1, y1 : Integer; speed : Byte);
Procedure SpriteMoveAngle(number, angle, speed : Byte);
Procedure SpriteMoveRel(number : Byte; xRel, yRel : Integer);

Implementation Library

End.
