(* Test 35 - A library unit's variables and routines
PSH IWU 0
SSP LBL xxxxx
PSH ILS 0
SSP LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 1
PSH VDW 4 1 0
SET IBS 4 IBS 2
PUF IBS 2 LBL xxxxx
PSH VDR 4 1 0
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 1e 1 1
PPF LBL xxxxx
PSH VDR 1e 1 1
JRP
LOC LBL xxxxx
POF IBS 0 IBS 0
*)

// The address of each variable a library declares is written to its
// jump table (SSP). A library's routine pointer is called with JRP.

Program Test;

Uses IcLib;

Begin
  LibCount := 1;
  LibProc(LibCount);
  LibCb;
End.
