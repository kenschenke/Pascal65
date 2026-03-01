(* Test 9 - Strings
SST ILS 0
PSH CHR 
BRA LBL xxxxx
LOC LBL xxxxx
PSH STR Hello, World
PSH VVW 15 1 0
SET IBS 15 IBS a
PSH IBS 5
PSH VVR 15 1 0
SSR
PSH VVW 9 1 1
SET IBS 9 IBS 9
PSH CHR a
PSH VVW 15 1 0
SET IBS 15 IBS 9
PSH VVR 9 1 1
PSH VVW 15 1 0
SET IBS 15 IBS 9
PSH STR Test
PSH VVR 9 1 1
CCT IBS a IBS 9
PSH VVW 15 1 0
SET IBS 15 IBS 16
*)

Program Test;

Var
  str : String;
  ch : Char;

Begin
  str := 'Hello, World';
  ch := str[5];
  str := 'a';
  str := ch;
  str := 'Test' + ch;
End.
