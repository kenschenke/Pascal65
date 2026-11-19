(* Test 45 - A library only a unit uses
HDR PRG test 0 200 0
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
IMP LIB iclib 6
   RRVVVR
FRM iclib 3
PSH IWU 0
SSP LBL iclib.2
PSH ILS 0
SSP LBL iclib.3
NEW IWS 4
DIR LBL xxxxx
SSP LBL iclib.4
UIC LBL icunit5.0
BRA LBL xxxxx
LOC LBL icunit5.0
UIR
LOC LBL icunit5.2
PSH VDR 4 2 0
PSH VDW 4 1 0 iclib
SET IBS 4 IBS 4
PUF IBS 2 LBL xxxxx
PSH VDR 4 2 0
ASF IBS 2
JSR LBL iclib.5 IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
RTS
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH IBS 4
ASF IBS 2
JSR LBL icunit5.2 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 4
EOM IBU 0
*)

// IcUnit5 uses IcLib and the program doesn't. The imports table comes
// from the units list, so IcLib is in it, after System, and its slots
// (iclib.N) are defined. The resolver puts IcLib before IcUnit5
// (orderUnits), so its variables are pushed first. It once came from the
// program's Uses alone, so IcLib had no jump table, no init or cleanup
// call and no slots, and the program didn't link.

Program Test;

Uses IcUnit5;

Begin
  Count(4);
End.
