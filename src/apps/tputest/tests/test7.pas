(* Test 7 - A unit that uses a unit loaded from its TPU
TPU 1 6 0 xxxx dee8
USE system bf05
USE test2 1f5f
INT 188 9
COD 115
HDR UNIT test7 0 0 1
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
IMP TPU test2
FRM test2 1
LOC LBL test7.0
PSH IWU 0
UIR
LOC LBL test7.2
PUF IBS 2 LBL xxxxx
PSH VDR 4 2 0
ASF IBS 2
JSR LBL test2.3 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH VDR 4 2 0
ASF IBS 2
JSR LBL test2.3 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 4 1 0
PSH VDR 4 1 0 test2
ADD IBS 4 IBS 4 IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
RTS
EOM IBU 0
*)

// Test2 is loaded from test2.tpu, which test 2 wrote, and TpuUnit and
// TpuLib, which only Test2 uses, are added to the units list from the
// TPU's list of the units it uses. Its CRC for Test2 must be test 2's.

Unit Test7;

Interface

Uses Test2;

Procedure AddTwice(n : Integer);

Implementation

Var
  Calls : Integer;

Procedure AddTwice(n : Integer);
Begin
  Add(n);
  Add(n);
  Calls := Calls + Sum;
End;

End.
