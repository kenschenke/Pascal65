(* Test 9 - A program that uses units loaded from their TPUs
HDR PRG test9 0 200 1
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
IMP TPU test1
IMP UNIT tpuunit
IMP TPU test2
IMP LIB tpulib 4
   RRVR
FRM test1 4
FRM tpuunit 1
FRM test2 1
FRM tpulib 1
PSH IWU 0
UIC LBL test1.0
UIC LBL tpuunit.0
UIC LBL test2.0
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
ASF IBS 2
JSR LBL test1.4 IBS 2 IBS 0
LOC LBL xxxxx
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH VDR 4 1 1 test1
ASF IBS 2
JSR LBL test1.5 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 4 1 0
SET IBS 4 IBS 4
PUF IBS 2 LBL xxxxx
PSH VDR 4 1 0
ASF IBS 2
JSR LBL test2.3 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
SFH IBS 80 IBS 0
PSH VDR 4 1 0 test2
PSH IBS 0
PSH IBS ff
OUT IBS 4
ONL
SFH IBS 0 IBS 0
EOM IBU 0
TPU 1 6 0 xxxx 9652
USE system bf05
INT 3fd 18
COD f2
HDR UNIT test1 0 0 4
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
LOC LBL test1.0
PSH IBS a
PSH IWU 0
NEW IWS 4
DIR LBL test1.3
PSH IWU 0
UIR
LOC LBL test1.4
PSH IBS 0
PSH VDW 4 1 1
SET IBS 4 IBS 2
PSH VDR 1 1 0
PSH VDR 14 1 2
SET IBS 4 IBS 1
PSH VDR 4 1 3
PSH IBS 1
ADD IBS 4 IBS 2 IBS 4
PSH VDW 4 1 3
SET IBS 4 IBS 4
RTS
LOC LBL test1.5
PSH VDR 4 2 0
ABS IBS 4
PSH IBS 2
MUL IBS 4 IBS 2 IBS 4
PSH RET 
SET IBS 4 IBS 4
RTS
DAT IBU 2 LBL test1.3
   heap offset: 0
   rec size: 4
EOM IBU 0
HDR UNIT tpuunit 0 0 1
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
LOC LBL tpuunit.0
PSH IWU 0
UIR
LOC LBL tpuunit.3
PSH VDR 4 1 0
PSH VDR 4 2 0
ADD IBS 4 IBS 4 IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
RTS
EOM IBU 0
TPU 1 6 0 xxxx 1f5f
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

// Test1 and Test2 are loaded from their TPUs: their imports are
// ICODE_IMPORT_TPU, icode writes no file for them and their code is
// dumped from their TPUs. TpuUnit, which only Test2 uses, is parsed from
// its source and has its own file. Test1's frame has its four slots.

Program Test9;

Uses Test1, Test2;

Var
  n : Integer;

Begin
  Clear;
  n := Twice(Count);
  Add(n);
  Writeln(Sum);
End.
