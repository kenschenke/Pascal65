(* Test 1 - A unit that uses only System
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
*)

Unit Test1;

Interface

Const
  Limit = 10;

Type
  Point = Record
    x, y : Integer;
  End;

Var
  Count : Integer;
  Origin : Point;

Procedure Clear;
Function Twice(n : Integer) : Integer;

Implementation

Var
  Calls : Integer;

Procedure Clear;
Begin
  Count := 0;
  Origin.x := Limit;
  Calls := Calls + 1;
End;

Function Twice(n : Integer) : Integer;
Begin
  Twice := Abs(n) * 2;
End;

End.
