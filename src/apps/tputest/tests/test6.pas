(* Test 6 - A unit that uses test 1
TPU 1 5 0 xxxx 7f4f
USE system bf05
USE test1 9652
INT 211 d
COD 130
HDR UNIT test6 0 0 1
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
IMP UNIT test1
FRM test1 4
LOC LBL test6.0
NEW IWS 4
DIR LBL test6.2
UIR
LOC LBL test6.3
PUF IBS 2 LBL xxxxx
ASF IBS 2
JSR LBL test1.4 IBS 2 IBS 0
LOC LBL xxxxx
POF IBS 0 IBS 0
PSH VDR 4 1 2 test1
PSH VDR 14 1 0
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 4
PUF IBS 2 LBL xxxxx
PSH VDR 4 2 0
ASF IBS 2
JSR LBL test1.5 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH RET 
SET IBS 4 IBS 4
RTS
DAT IBU 2 LBL test6.2
   heap offset: 0
   rec size: 4
EOM IBU 0
*)

// The CRC it has for Test1 must be test 1's interface CRC

Unit Test6;

Interface

Uses Test1;

Var
  Corner : Point;

Function Scaled(n : Integer) : Integer;

Implementation

Function Scaled(n : Integer) : Integer;
Begin
  Clear;
  Corner.y := Count;
  Scaled := Twice(n);
End;

End.
