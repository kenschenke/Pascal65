(* Test 43 - References to another module's entries
HDR PRG test 0 200 1
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
FRM icunit3 3
PSH ILS 0
UIC LBL icunit3.0
BRA LBL xxxxx
MDL IBU 1
LOC LBL icunit3.0
PSH IWU 0
NEW IWS 4
DIR LBL icunit3.2
NEW IWS 6
DIA LBL icunit3.3
UIR
LOC LBL icunit3.5
PSH VDR 4 1 0
PSH VDR 4 2 0
ADD IBS 4 IBS 4 IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
RTS
LOC LBL icunit3.4
PUF IBS 2 LBL xxxxx
PSH VDR 14 2 0
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
ASF IBS 2
JSR LBL icunit3.5 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
RTS
MDL IBU 0
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH VDR 14 1 1 icunit3
DCC LBL icunit3.2 IBS 2
ASF IBS 2
JSR LBL icunit3.4 IBS 2 IBS 0
LOC LBL xxxxx
DCF LBL icunit3.2 IBS 2
POF IBS 0 IBS 0
PSH VDW b 1 2 icunit3
PSH IBS 3
CVI IBS 2 IBS 6
SAL LBL icunit3.3
PRP LBL icunit3.5 IBS 2 IBS 0
PSH VDW 1e 1 0
SET IBS 1e IBS 1d
PUF IBS 2 LBL xxxxx
PSH IBS 2
ASF IBS 2
JSR LBL icunit3.5 IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
SFH IBS 80 IBS 0
PSH VDR b 1 2 icunit3
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
PSH IBS 1
ADD IBS 4 IBS 1 IBS 4
PSH IBS 0
PSH IBS ff
OUT IBS 4
ONL
SFH IBS 0 IBS 0
DAT IBU 2 LBL icunit3.2
   heap offset: 0
   rec size: 4
DAT IBU 5 LBL icunit3.3
   heap offset: 0
   low bound: 0
   high bound: -1
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
EOM IBU 1
*)

// A reference to a unit's or library's entry names the module and the
// entry's number: 0 the init, 1 the cleanup, then the interface's
// routines and variables in order (Origin 2, Vals 3, Show 4, Bump 5).
// The unit's init block, its routines' LOCs and its variables' blocks
// are named the same way, so each call (JSR, from the program and from
// Show), @Bump (PRP), passing Origin by value (DCC) and SetLength of Vals
// (SAL) name the entry. Count is in the implementation, so its labels
// stay the unit's own.

Program Test;

Uses IcUnit3;

Type
  NumProc = Procedure(n : Integer);

Var
  np : NumProc;

Begin
  Show(Origin);
  SetLength(Vals, 3);
  np := @Bump;
  Bump(2);
  WriteLn(Length(Vals));
End.
