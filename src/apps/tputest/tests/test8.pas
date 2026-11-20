(* Test 8 - A unit that uses a unit with only a TPU
TPU 1 6 0 xxxx b31
USE system bf05
USE tpucrc e8f0
INT e4 5
COD c9
HDR UNIT test8 0 0 0
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
IMP TPU tpucrc
FRM tpucrc 1
LOC LBL test8.0
UIR
LOC LBL test8.2
PUF IBS 2 LBL xxxxx
PSH IBS 2
ASF IBS 2
JSR LBL tpucrc.3 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 4 1 0 tpucrc
PSH IBS 1
ADD IBS 4 IBS 2 IBS 4
PSH VDW 4 1 0 tpucrc
SET IBS 4 IBS 4
RTS
EOM IBU 0
*)

// TpuCrc has no source on the disk, only tpucrc.tpu, which test 5 wrote,
// so it can only be loaded from it. Its CRC for TpuCrc must be test 5's,
// and its frame has TpuCrc's one slot.

Unit Test8;

Interface

Procedure Bump;

Implementation

Uses TpuCrc;

Procedure Bump;
Begin
  Add(2);
  Total := Total + 1;
End;

End.
