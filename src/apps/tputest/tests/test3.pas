(* Test 3 - TpuCrc, the unit tests 4 and 5 change
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
ADD IBS 4 IBS 4 IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
RTS
EOM IBU 0
*)

// Tests 4 and 5 keep every line of the interface where it is here

Unit TpuCrc;

Interface

Var
  Total : Integer;

Procedure Add(n : Integer);

Implementation

Procedure Add(n : Integer);
Begin
  Total := Total + n;
End;

End.
