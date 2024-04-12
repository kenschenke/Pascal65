(*
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Screen Library
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Unit Screen;

Interface

(* Rows and columns start with 1 *)

Procedure ClearScreen();
Procedure DrawChar(col, row : Byte; ch : Char);
Procedure DrawCharRaw(col, row : Byte; ch : Char);
Procedure DrawText(col, row : Byte; text : String);
Procedure DrawTextRaw(col, row : Byte; text : String);
Procedure GetScreenSize(Var cols, rows : Byte);
Procedure SetBackgroundColor(color : Byte);
Procedure SetBorderColor(color : Byte);
Procedure SetLowerCase;
Procedure SetReverse(reverse : Boolean);
Procedure SetScreenSize(cols, rows : Byte);
Procedure SetTextColor(color : Byte);
Procedure SetUpperCase;

Implementation Library

End.
