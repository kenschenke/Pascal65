Unit System;

Interface

(*
String Routines in system.lib:
All indexes are 1-based
Function BeginsWith(str, sub : String) : Boolean;
Function Contains(str, sub : String) : Boolean;
Function Copy(str : String; index, count : Byte) : String;
Procedure Delete(Var str : String; index, count : Byte);
Function EndsWith(str, sub : String) : Boolean;
Procedure Insert(source : String; Var str : String; index : Byte);
Function Pos(substr : String; str : String; offset : Byte) : Byte;
ShortCompareText?

In Runtime:
Function Concat(s1, s2, s3, s4, ... : String) : String;
Str
Val
*)

Function Chr(Num : Integer) : Char;
Function Odd(Num : LongInt) : Boolean;
Function Length(str : String) : Byte;
Function LowerCase(str : String) : String;
Function Peek(Address : Word) : Byte;
Procedure Poke(Address : Word; Value : Byte);
Function StringOfChar(ch : Char; count : Byte) : String;
Function Trim(str : String) : String;
Function UpCase(str : String) : String;

Implementation Library

End.
