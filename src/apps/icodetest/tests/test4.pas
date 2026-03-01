(* Test 4 - While loop
PSH IWU 1
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
LOC LBL xxxxx
PSH VVR 4 1 0
PSH IBS 5
LST IBS 4 IBS 1
BIF LBL xxxxx
PSH VVR 4 1 0
PSH IBS 5
MUL IBS 4 IBS 1 IBS 6
PSH VVW 4 1 1
SET IBS 4 IBS 6
BRA LBL xxxxx
LOC LBL xxxxx
LOC LBL xxxxx
PSH VVR 4 1 0
PSH IBS a
LST IBS 4 IBS 1
BIF LBL xxxxx
PSH VVR 4 1 0
PSH IBS 5
MUL IBS 4 IBS 1 IBS 6
PSH VVW 4 1 1
SET IBS 4 IBS 6
PSH VVR 4 1 1
PSH IBS 1
ADD IBS 4 IBS 1 IBS 6
PSH VVW 4 1 1
SET IBS 4 IBS 6
BRA LBL xxxxx
LOC LBL xxxxx
*)

Program Test;

Var
  i : Integer = 1;
  j : Integer;

Begin
  While i < 5 Do
    j := i * 5;
  
  While i < 10 Do Begin
    j := i * 5;
    j := j + 1
  End;
End.
