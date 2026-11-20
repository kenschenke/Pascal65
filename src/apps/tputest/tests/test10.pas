(* Test 10 - Routine addresses in a unit loaded from its TPU
HDR PRG test10 0 200 2
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
IMP TPU test1
FRM test1 4
PSH ILS 0
PSH ILS 0
UIC LBL test1.0
BRA LBL xxxxx
LOC LBL xxxxx
PRP LBL test1.5 IBS 2 IBS 0
PSH VDW 1e 1 0
SET IBS 1e IBS 1d
PRP LBL test1.4 IBS 2 IBS 0
PSH VDW 1e 1 1
SET IBS 1e IBS 1d
PSH VDR 1e 1 1
PPF LBL xxxxx
PSH VDR 1e 1 1
JRP
LOC LBL xxxxx
POF IBS 0 IBS 0
SFH IBS 80 IBS 0
PSH VDR 1e 1 0
PPF LBL xxxxx
PSH IBS 2
PSH VDR 1e 1 0
JRP
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
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
*)

// Test1 is loaded from its TPU, so its routines' symbols name their
// interface declarations, which have no code, not their bodies. Taking
// their addresses must make PRP, as for a unit parsed from its source.

Program Test10;

Uses Test1;

Type
  IntFunc = Function(n : Integer) : Integer;
  NoArgs = Procedure;

Var
  f : IntFunc;
  p : NoArgs;

Begin
  f := @Twice;
  p := @Clear;
  p;
  Writeln(f(2));
End.
