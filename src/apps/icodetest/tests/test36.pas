(* Test 36 - A unit with code
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 4 1 0
PSH VDR 4 2 0
ADD IBS 4 IBS 4 IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
RTS
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH IBS 5
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 4 1 0
PSH IBS 1
ADD IBS 4 IBS 2 IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
*)

// A unit's routines are written in the unit's scope.

Program Test;

Uses IcUnit;

Begin
  AddTo(5);
  Total := Total + 1;
End.
