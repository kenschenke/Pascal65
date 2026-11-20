(* Test 4 - TpuCrc with only its implementation changed
TPU 1 6 0 xxxx cd5a
USE system bf05
INT 188 9
COD 7f
HDR UNIT tpucrc 0 0 1
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
LOC LBL tpucrc.0
PSH IWU 0
UIR
LOC LBL tpucrc.3
PSH VDR 4 1 0
PSH VDR 4 2 0
SUB IBS 4 IBS 4 IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
RTS
EOM IBU 0
*)

// Its interface's CRC must be test 3's (checktpu.s)

Unit TpuCrc;

Interface

Var
  Total : Integer;

Procedure Add(n : Integer);

Implementation

Procedure Add(n : Integer);
Begin
  Total := Total - n;
End;

End.
