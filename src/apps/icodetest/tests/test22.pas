(* Test 22 - Constants
PSH IWU 3039
PSH FLT 3.14159
SST STR Hello World
PSH BOO 1
PSH CHR x
PSH IWU 0
PSH FLT 
SST ILS 0
PSH BOO 0
PSH CHR 
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 3 1 0
PSH IWU 2b67
ADD IBS 3 IBS 3 IBS 3
PSH VDW 4 1 5
SET IBS 4 IBS 3
PSH VDR 7 1 1
PSH IBS 2
MUL IBS 7 IBS 2 IBS 7
PSH VDW 7 1 6
SET IBS 7 IBS 7
PSH VDR 15 1 2
PSH VDR 9 1 4
CCT IBS 15 IBS 9
PSH VDW 15 1 7
SET IBS 15 IBS 16
PSH VDR 8 1 3
PSH VDW 8 1 8
SET IBS 8 IBS 8
PSH VDR 9 1 4
PSH VDW 9 1 9
SET IBS 9 IBS 9
*)

Program Test;

Const
  MyInt = 12345;
  Pi = 3.14159;
  Greeting = 'Hello World';
  Yes = True;
  LetterX = 'x';

Var
  i : Integer;
  r : Real;
  str : String;
  b : Boolean;
  ch : Char;

Begin
  i := MyInt + 11111;
  r := Pi * 2;
  str := Greeting + LetterX;
  b := Yes;
  ch := LetterX;
End.
