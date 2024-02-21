(* Screen *)

Unit Screen;

Interface

Const
    Black = 0;
    White = 1;
    Red = 2;
    Cyan = 3;
    Purple = 4;
    Green = 5;
    Blue = 6;
    Yellow = 7;
    Orange = 8;
    Brown = 9;
    Pink = 10;
    DarkGrey = 11;
    Grey = 12;
    LightGreen = 13;
    LightBlue = 14;
    LightGrey = 15;

(* Rows and columns start with 1 *)

Procedure ClrScn();
Procedure DrawText(col, row : Byte; text : String);
Procedure FillScreen(col, row : Byte; width, height : Byte; ch : Char);
Procedure GetScreenSize(Var cols, rows : Byte);
Procedure MoveCursor(col, row : Byte);
Procedure SetBackgroundColor(color : Byte);
Procedure SetBorderColor(color : Byte);
Procedure SetTextColor(color : Byte);

Implementation Library
