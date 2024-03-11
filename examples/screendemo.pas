Program ScreenDemo;

Uses Screen;

Const
    UpperLeft = $e9;
    UpperRight = $df;
    LowerRight = $69;
    LowerLeft = $5f;
    Block = $a0;
    Space = $20;

Var
    color : Byte;

Procedure DrawP(col, row : Byte);
Var
    y : Byte;
Begin
    DrawTextRaw(col, row,
        Chr(UpperLeft) + StringOfChar(Chr(Block), 4) + Chr(UpperRight));
    For y := row+1 To row+3 Do
        DrawTextRaw(col, y, Chr(Block) + '    ' + Chr(Block));
    DrawTextRaw(col, row+4, StringOfChar(Chr(Block), 5) + Chr(LowerRight));
    For y := row+5 To row+8 Do DrawCharRaw(col, y, Chr(Block));
End;

Procedure DrawA(col, row : Byte);
Var
    y : Byte;
Begin
    DrawTextRaw(col, row+4, Chr(UpperLeft) + Chr(Block) + Chr(Block) +
        Chr(UpperRight));
    For y := row+5 To row+7 Do
        DrawTextRaw(col, y,
            Chr(Block) + Chr(Space) + Chr(Space) + Chr(Block));
    DrawTextRaw(col, row+8, Chr(LowerLeft) + StringOfChar(Chr(Block), 4));
End;

Procedure DrawS(col, row : Byte);
Begin
    DrawTextRaw(col, row+4, Chr(UpperLeft) + Chr(Block) +
        Chr(Block) + Chr(UpperRight));
    DrawCharRaw(col, row+5, Chr(Block));
    DrawTextRaw(col, row+6, StringOfChar(Chr(Block), 3) + Chr(UpperRight));
    DrawCharRaw(col+3, row+7, Chr(Block));
    DrawTextRaw(col, row+8, Chr(LowerLeft) + Chr(Block) +
        Chr(Block) + Chr(LowerRight));
End;

Procedure DrawC(col, row : Byte);
Var
    y : Byte;
Begin
    DrawTextRaw(col, row+4, Chr(UpperLeft) + Chr(Block) +
        Chr(Block) + Chr(UpperRight));
    For y := row+5 To row+7 Do DrawCharRaw(col, y, Chr(Block));
    DrawTextRaw(col, row+8, Chr(LowerLeft) + Chr(Block) +
        Chr(Block) + Chr(LowerRight));
End;

Procedure DrawL(col, row : Byte);
Var
    y : Byte;
Begin
    For y := row To row + 7 Do DrawCharRaw(col, y, Chr(Block));
    DrawTextRaw(col, row+8, Chr(LowerLeft) + Chr(Block));
End;

Procedure Draw6(col, row : Byte);
Var
    y : Byte;
Begin
    DrawTextRaw(col, row, Chr(UpperLeft) + StringOfChar(Chr(Block), 4) +
        Chr(UpperRight));
    For y := row+1 To row+7 Do DrawCharRaw(col, y, Chr(Block));
    DrawTextRaw(col+1, row+4, StringOfChar(Chr(Block), 4) + Chr(UpperRight));
    For y := row+5 To row+7 Do DrawCharRaw(col+5, y, Chr(Block));
    DrawTextRaw(col, row+8, Chr(LowerLeft) + StringOfChar(Chr(Block), 4) +
        Chr(LowerRight));
End;

Procedure Draw5(col, row : Byte);
Var
    y : Byte;
Begin
    DrawTextRaw(col, row, StringOfChar(Chr(Block), 6));
    For y := row+1 To row+3 Do DrawCharRaw(col, y, Chr(Block));
    DrawTextRaw(col, row+4, StringOfChar(Chr(Block), 5) + Chr(UpperRight));
    For y := row+5 To row+7 Do DrawCharRaw(col+5, y, Chr(Block));
    DrawTextRaw(col, row+8, StringOfChar(Chr(Block), 5) + Chr(LowerRight));
End;

Procedure DrawGrid(col, row : Byte);
Var
    c, r, x, y : Byte;
    chunk, strand : String;
Begin
    y := row;
    chunk := StringOfChar(Chr(Block), 2);
    strand := chunk + ' ' + chunk + ' ' + chunk;
    For r := 1 To 3 Do Begin
        DrawTextRaw(col, y, strand);
        DrawTextRaw(col, y+1, strand);

        y := y + 3;
    End;
End;

Begin
    SetBackgroundColor(0);  // Black
    SetBorderColor(0);      // Black
    SetUpperCase();
    ClearScreen();
    SetTextColor(1);

    color := 2;
    SetTextColor(color);
    color := color + 1;
    SetTextColor(color);

    DrawP(5, 7);
    color := color + 1;
    SetTextColor(color);
    DrawA(12, 7);
    color := color + 1;
    SetTextColor(color);
    DrawS(18, 7);
    color := color + 1;
    SetTextColor(color);
    DrawC(23, 7);
    color := color + 1;
    SetTextColor(color);
    DrawA(28, 7);
    color := color + 1;
    SetTextColor(color);
    DrawL(34, 7);
    color := color + 1;
    SetTextColor(color);

    Draw6(8, 17);
    color := color + 1;
    SetTextColor(color);
    Draw5(15, 17);
    color := color + 1;
    SetTextColor(color);

    DrawGrid(25, 17);
End.
