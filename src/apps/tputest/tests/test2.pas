(* Test 2 - A unit that uses a unit and a library
TPU 1 5 0 xxxx 1f5f
USE system bf05
USE tpuunit 8556
USE tpulib 53ee
INT 1e5 b
COD 148
HDR UNIT test2 0 0 1
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
IMP UNIT tpuunit
IMP LIB tpulib 4
   RRVR
FRM tpuunit 1
FRM tpulib 1
LOC LBL test2.0
PSH IWU 0
UIR
LOC LBL test2.3
PSH VDR 4 1 0
PSH VDR 4 2 0
ADD IBS 4 IBS 4 IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
PUF IBS 2 LBL xxxxx
PSH VDR 4 2 0
ASF IBS 2
JSR LBL tpuunit.3 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 4 1 0 tpuunit
PSH VDW 4 1 0 tpulib
SET IBS 4 IBS 4
PUF IBS 2 LBL xxxxx
PSH VDR 4 1 0
ASF IBS 2
JSR LBL tpulib.3 IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
RTS
EOM IBU 0
*)

// It uses TpuUnit in its interface and TpuLib in its implementation

Unit Test2;

Interface

Uses TpuUnit;

Var
  Sum : Integer;

Procedure Add(n : Integer);

Implementation

Uses TpuLib;

Procedure Add(n : Integer);
Begin
  Sum := Sum + n;
  AddTo(n);
  LibCount := Total;
  LibProc(Sum);
End;

End.
