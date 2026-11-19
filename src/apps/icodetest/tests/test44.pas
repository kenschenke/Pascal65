(* Test 44 - A unit named by the program and by another unit
HDR PRG test 0 200 0
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
FRM icunit 1
UIC LBL icunit.0
UIC LBL icunit4.0
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
LOC LBL icunit4.0
UIR
LOC LBL icunit4.2
PUF IBS 2 LBL xxxxx
PSH VDR 4 2 0
ASF IBS 2
JSR LBL icunit.3 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH VDR 4 2 0
ASF IBS 2
JSR LBL icunit.3 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
RTS
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH IBS 3
ASF IBS 2
JSR LBL icunit4.2 IBS 2 IBS 0
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

// IcUnit is named twice, by the program and by IcUnit4, but it is one
// unit: one init block (UIC) and one frame. The parser's comparison of
// unit names (addUnit) once never matched, so it was added twice.

Program Test;

Uses IcUnit, IcUnit4;

Begin
  Twice(3);
  Total := Total + 1;
End.
