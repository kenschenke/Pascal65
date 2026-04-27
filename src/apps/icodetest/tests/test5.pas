(* Test 5 - Repeat..Until
PSH IWU 1
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
LOC LBL xxxxx
PSH VDR 4 1 0
PSH IBS 1
ADD IBS 4 IBS 1 IBS 6
PSH VDW 4 1 0
SET IBS 4 IBS 6
PSH VDR 4 1 0
PSH IBS 5
MUL IBS 4 IBS 1 IBS 6
PSH VDW 4 1 1
SET IBS 4 IBS 6
PSH VDR 4 1 0
PSH IBS 5
GRT IBS 4 IBS 1
BIF LBL xxxxx
*)

Program Test;

Var
  i : Integer = 1;
  j : Integer;

Begin
  Repeat
    i := i + 1;
    j := i * 5;
  Until i > 5;
End.
