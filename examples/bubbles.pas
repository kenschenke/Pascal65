(*
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Bubbles bouncing on screen using sprites
 * 
 * Copyright (c) 2025
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Program Bubbles;

Uses Screen, Sprites, SpriteMove;

Const
    Pi = 3.14159;
    xMin = 24;
    xMax = 321;
    yMin = 50;
    yMax = 230;
    maxSprites = 8;

Var
    s, y0, y1 : Byte;
    x0, x1 : Word;
    rad : Real;
    angles : Array[0..7] Of Word;
    bouncing : Array[0..7] Of Boolean;
    // Sprite data for bubble
    data : Array[1..63] Of Byte = (
      0, 255,   0,
      3, 129, 192,
     14,   0, 112,
     56,   0,  28,
     32,   0,   4,
     96,   6,   6,
     64,   1, 130,
    192,   0, 195,
    128,   0,  65,
    128,   0,  33,
    128,   0,   1,
    128,   0,   1,
    128,   0,   1,
    192,   0,   1,
     64,   0,   3,
     96,   0,   6,
     32,   0,   4,
     56,   0,  28,
     14,   0, 112,
      3, 129, 192,
      0, 255,   0,
    );

Procedure CoordinateAtAngle(xStart: Word; Var xEnd : Word;
    yStart : Byte; Var yEnd : Byte; angle : Word);
Var
    r : Real;
Begin
    r := angle * rad;  // Convert degrees to radians

    // Calculate the X and Y coordinates of the point at the angle
    // on a cicle of radius 25, centered at xStart, yStart
    xEnd := xStart + Round(25 * Cos(r));
    yEnd := yStart + Round(25 * Sin(r));
End;

Function GetReflectionAngle(x : Word; y : Byte; oldAngle : Word) : Word;
Var
    newAngle : Word;
Begin
    If (x <= xMin) Or (x >= xMax) Then Begin
        // Vertical surface (left or right side)
        newAngle := 540 - oldAngle;
        If newAngle > 360 Then newAngle := newAngle - 360;
    End Else
        // Horizontal surface (top or bottom):
        newAngle := 360 - oldAngle;
    GetReflectionAngle := newAngle;
End;

Function RandomX : Word;
Begin
    // Generate a random number between 60 and 280
    RandomX := Round(((Peek($d7ef)+Peek($d7ef))/512) * 220) + 60;
End;

Function RandomY : Byte;
Begin
    // Generate a random number between 80 and 200
    RandomY := Round((Peek($d7ef) / 256) * 120) + 80;
End;

Procedure NormalizePos(Var x : Word; Var y : Byte);
Begin
    If x < xMin Then x := xMin;
    If x > xMax Then x := xMax;
    If y < yMin Then y := yMin;
    If y > yMax Then y := yMax;
End;

Procedure SetupScreen;
Begin
    // Background and border
    SetBackgroundColor(0);
    SetBorderColor(11);
    ClearScreen;
End;

Procedure SetupSprites;
Var
    i, yStart, yEnd : Byte;
    d, xStart, xEnd : Word;
Begin
    // Set the image data for each sprite and enable it
    For i := 0 To maxSprites-1 Do Begin
        SpriteData(i, @data[1]);
        Sprite(i, i+1, true, false);
        xStart := RandomX;
        yStart := RandomY;
        bouncing[i] := false;
        // Generate a random angle between 0 and 360
        d := Round(((Peek($d7ef)+Peek($d7ef))/512) * 360);
        angles[i] := d;
        CoordinateAtAngle(xStart, xEnd, yStart, yEnd, d);
        SpriteMove(i, xStart, yStart, xEnd, yEnd, 1, false);
    End;
End;

// Main Procedure
Begin
    rad := Pi / 180.0;

    SetupScreen;
    SetupSprites;

    Repeat
        For s := 0 To maxSprites-1 Do Begin
            GetSpritePos(s, x0, y0);
            If (x0 >= xMin) And (x0 <= xMax) And
                (y0 >= yMin) And (y0 <= yMax) Then
                bouncing[s] := false
            Else If Not bouncing[s] Then Begin
                // Sprite outside walls
                NormalizePos(x0, y0);
                angles[s] := GetReflectionAngle(x0, y0, angles[s]);
                // Writeln('Reflection angle: ', angles[s]);
                CoordinateAtAngle(x0, x1, y0, y1, angles[s]);
                SpriteMove(s, x0, y0, x1, y1, 1, false);
                bouncing[s] := true;
            End;
        End;
    Until False;
End.
