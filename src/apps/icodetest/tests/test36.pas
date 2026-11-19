(* Test 36 - A unit with code
HDR PRG test 0 200 0
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
FRM icunit 1
UIC LBL icunit.0
BRA LBL xxxxx
LOC LBL icunit.0
PSH IWU 0
UIR
LOC LBL icunit.3
PSH VDR 4 1 0 icunit
PSH VDR 4 2 0
ADD IBS 4 IBS 4 IBS 4
PSH VDW 4 1 0 icunit
SET IBS 4 IBS 4
RTS
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH IBS 5
ASF IBS 2
JSR LBL icunit.3 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 4 1 0 icunit
PSH IBS 1
ADD IBS 4 IBS 2 IBS 4
PSH VDW 4 1 0 icunit
SET IBS 4 IBS 4
EOM IBU 0
*)

// A unit's routines are written in the unit's scope. Its variables are
// pushed by its init block, which the startup calls with UIC and which
// ends with UIR. The block comes before the unit's routines.

Program Test;

Uses IcUnit;

Begin
  AddTo(5);
  Total := Total + 1;
End.
