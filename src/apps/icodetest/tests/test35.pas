(* Test 35 - A library unit's variables and routines
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
BRA LBL xxxxx
LOC LBL xxxxx
RTS
LOC LBL xxxxx
PSH IBS 1
PSH VDW 4 1 0 iclib
SET IBS 4 IBS 2
PUF IBS 2 LBL xxxxx
PSH VDR 4 1 0 iclib
ASF IBS 2
JSR LBL iclib.5 IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 1e 1 1 iclib
PPF LBL xxxxx
PSH VDR 1e 1 1 iclib
JRP
LOC LBL xxxxx
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH VDR 14 1 2 iclib
DCC LBL xxxxx IBS 2
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
DCF LBL xxxxx IBS 2
POF IBS 0 IBS 0
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 4
EOM IBU 0
*)

// The address of each variable a library declares is written to its
// jump table (SSP), which is named for the library and the slot. A
// library's record is set up by the program's startup, so its block keeps
// its own label, which passing it by value (DCC, DCF) names too. A
// library's routine pointer is called with JRP.

Program Test;

Uses IcLib;

Procedure Show(p : LibRec);
Begin
End;

Begin
  LibCount := 1;
  LibProc(LibCount);
  LibCb;
  Show(LibPt);
End.
