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

(*
Future string routines
Function Copy(str : String; index, count : Byte) : String;
Procedure Delete(Var str : String; index, count : Byte);
Procedure Insert(source : String; Var str : String; index : Byte);
*)

Function BeginsWith(str, sub : String) : Boolean;
Function Chr(Num : Integer) : Char;
Function CompareStr(s1, s2 : String) : ShortInt;
Function Contains(str, sub : String) : Boolean;
Function EndsWith(str, sub : String) : Boolean;
Function GetKey : Char;
Function GetKeyNoWait : Char;
Function Odd(Num : LongInt) : Boolean;
Function Length(str : String) : Byte;
Function LowerCase(str : String) : String;
Function Peek(Address : Word) : Byte;
Procedure Poke(Address : Word; Value : Byte);
Function StrPos(str, sub : String; offset : Byte) : Byte;
Function StringOfChar(ch : Char; count : Byte) : String;
Function Trim(str : String) : String;
Function UpCase(str : String) : String;

Implementation Library

End.
