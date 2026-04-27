(* Test 9 - Strings
SST ILS 0
PSH CHR 
BRA LBL xxxxx
LOC LBL xxxxx
PSH STR Hello, World
PSH VDW 15 1 0
SET IBS 15 IBS a
PSH IBS 5
PSH VDR 15 1 0
SSR
PSH VDW 9 1 1
SET IBS 9 IBS 9
PSH CHR a
PSH VDW 15 1 0
SET IBS 15 IBS 9
PSH VDR 9 1 1
PSH VDW 15 1 0
SET IBS 15 IBS 9
PSH STR Test
PSH VDR 9 1 1
CCT IBS a IBS 9
PSH VDW 15 1 0
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
