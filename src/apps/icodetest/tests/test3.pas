(* Test 3 - Scalar Variable Initial Values
PSH IBS 7b
PSH IBS ea
PSH BOO 1
PSH IWU 3039
PSH IWU 8707
PSH ILS 1e240
PSH ILS 8bd03835
PSH FLT 3.14
SST STR Hello, World
PSH CHR x
BRA LBL xxxxx
LOC LBL xxxxx
*)

Program Test;

Var
  a : ShortInt = 123;
  b : Byte = 234;
  bool : Boolean = True;
  i : Integer = 12345;
  w : Word = 34567;
  l : LongInt = 123456;
  c : Cardinal = 2345678901;
  r : Real = 3.14;
  str : String = 'Hello, World';
  ch : Char = 'x';

Begin
End.
