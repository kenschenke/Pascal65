(* Test 1 - Scalar Variable Assignments
PSH IBS 0
PSH IBS 0
PSH BOO 0
PSH IWU 0
PSH IWU 0
PSH ILS 0
PSH ILS 0
PSH FLT 
SST ILS 0
PSH CHR 
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 7b
PSH VDW 2 1 0
SET IBS 2 IBS 2
PSH IBS fb
PSH VDW 2 1 0
SET IBS 2 IBS 2
PSH IBS ea
PSH VDW 1 1 1
SET IBS 1 IBS 1
PSH BOO 1
PSH VDW 8 1 2
SET IBS 8 IBS 8
PSH IWU 3039
PSH VDW 4 1 3
SET IBS 4 IBS 4
PSH IWU fb2e
PSH VDW 4 1 3
SET IBS 4 IBS 4
PSH IWU 8707
PSH VDW 3 1 4
SET IBS 3 IBS 3
PSH ILS 1e240
PSH VDW 6 1 5
SET IBS 6 IBS 6
PSH ILS fffe1dc0
PSH VDW 6 1 5
SET IBS 6 IBS 6
PSH ILS 8bd03835
PSH VDW 5 1 6
SET IBS 5 IBS 5
PSH FLT 3.14
PSH VDW 7 1 7
SET IBS 7 IBS 7
PSH STR Hello, World
PSH VDW 15 1 8
SET IBS 15 IBS a
PSH CHR x
PSH VDW 9 1 9
SET IBS 9 IBS 9
*)

Program Test;

Var
  a : ShortInt;
  b : Byte;
  bool : Boolean;
  i : Integer;
  w : Word;
  l : LongInt;
  c : Cardinal;
  r : Real;
  str : String;
  ch : Char;

Begin
  a := 123;
  a := -5;
  b := 234;
  bool := True;
  i := 12345;
  i := -1234;
  w := 34567;
  l := 123456;
  l := -123456;
  c := 2345678901;
  r := 3.14;
  str := 'Hello, World';
  ch := 'x';
End.
