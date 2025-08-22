(*
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * System Library (included automatically)
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Unit System;

Interface

Type
    RasterCb = Procedure;

(*
Future string routines
Function Copy(str : String; index, count : Byte) : String;
Procedure Delete(Var str : String; index, count : Byte);
Procedure Insert(source : String; Var str : String; index : Byte);
*)

Procedure Assign(Var f : File; filename : String);
Function BeginsWith(str, sub : String) : Boolean;
Function Chr(Num : Integer) : Char;
Procedure Close(Var f : File);
Function CompareStr(s1, s2 : String) : ShortInt;
Function Contains(str, sub : String) : Boolean;
Function Cos(angle : Real) : Real;
Function EndsWith(str, sub : String) : Boolean;
Function EOF(Var f : File) : Boolean;
Procedure Erase(Var f : File);
Function GetKey : Char;
Function GetKeyNoWait : Char;
Function IOResult : Word;
Function Length(str : String) : Byte;
Function LowerCase(str : String) : String;
Function Odd(Num : LongInt) : Boolean;
Function Peek(Address : Cardinal) : Byte;
Function PeekW(Address : Cardinal) : Word;
Function PeekL(Address : Cardinal) : Cardinal;
Procedure Poke(Address : Cardinal; Value : Byte);
Procedure PokeW(Address : Cardinal; Value : Word);
Procedure PokeL(Address : Cardinal; Value : Cardinal);
Procedure Rename(Var f : File; newName : String);
Procedure Reset(Var f : File);
Procedure Rewrite(Var f : File);
Procedure SetRasterCallback(callback : RasterCb);
Function Sin(angle : Real) : Real;
Function StrPos(str, sub : String; offset : Byte) : Byte;
Function StringOfChar(ch : Char; count : Byte) : String;
Function Tan(angle : Real) : Real;
Function Trim(str : String) : String;
Function UpCase(str : String) : String;

Implementation Library

End.
