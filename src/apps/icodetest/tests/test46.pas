(* Test 46 - A unit compiled on its own
HDR UNIT test46 0 0 3
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
IMP UNIT icunit
IMP LIB iclib 6
   RRVVVR
FRM icunit 1
FRM iclib 3
LOC LBL test46.0
PSH IWU 0
PSH IWU 0
NEW IWS 4
DIR LBL test46.3
UIR
LOC LBL test46.4
PSH VDR 4 1 1
PSH VDR 4 2 0
ADD IBS 4 IBS 4 IBS 4
PSH VDW 4 1 1
SET IBS 4 IBS 4
PSH VDR 4 1 0 icunit
PSH VDW 4 1 0
SET IBS 4 IBS 4
PUF IBS 2 LBL xxxxx
PSH VDR 4 2 0
ASF IBS 2
JSR LBL icunit.3 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 4 1 1
PSH VDW 4 1 0 iclib
SET IBS 4 IBS 4
PUF IBS 2 LBL xxxxx
PSH VDR 4 2 0
ASF IBS 2
JSR LBL iclib.5 IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 4 2 0
PSH VDR 14 1 2
SET IBS 4 IBS 4
RTS
DAT IBU 2 LBL test46.3
   heap offset: 0
   rec size: 4
EOM IBU 0
*)

// The source is a unit, so it is compiled on its own (unit mode), as it
// will be to its TPU: icode writes only the unit's own file. It must be
// the same as the unit's file in test 47, a program that uses it. It uses
// IcUnit in its interface and IcLib in its implementation, so its
// imports and frames come from both of its Uses.

Unit Test46;

Interface

Uses IcUnit;

Type
  Pair = Record
    a, b : Integer;
  End;

Var
  Count : Integer;
  Pt : Pair;

Procedure Bump(n : Integer);

Implementation

Uses IcLib;

Var
  Hidden : Integer;

Procedure Bump(n : Integer);
Begin
  Count := Count + n;
  Hidden := Total;
  AddTo(n);
  LibCount := Count;
  LibProc(n);
  Pt.a := n;
End;

End.
