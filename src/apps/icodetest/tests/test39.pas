(* Test 39 - A unit's init block and a library's variables
HDR PRG test 0 200
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
IMP LIB iclib 5
   RRVVR
PSH IWU 0
UIC LBL xxxxx
PSH IWU 0
SSP LBL xxxxx
PSH ILS 0
SSP LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
NEW IWS 4
DIR LBL xxxxx
SST STR hi
NEW IWS a
DIA LBL xxxxx
UIR
LOC LBL xxxxx
PSH IBS 1
PSH VDR 14 1 1
SET IBS 4 IBS 2
RTS
LOC LBL xxxxx
PSH VDR b 1 3
PSH IBS 2
AIX IBS 2
MEM IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
PSH VDR 4 1 0
PSH VDW 4 1 4
SET IBS 4 IBS 4
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 4
DAT IBU 0 LBL xxxxx
   05 00 06 00 
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 2
   elem size: 2
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 2
EOM IBU 0
*)

// The units' variables follow the program's, in Uses order. IcUnit2's
// are pushed by its init block (UIC, then LOC ... UIR before its
// routines), with the heap allocations for its string, array and record.
// IcLib is a library, so its variables are pushed in the startup itself,
// after IcUnit2's. LibCount is slot 4: every unit once started right
// after the program's variables (setDeclOffsets), so it shared P's, 1.

Program Test;

Uses IcUnit2, IcLib;

Var
  n : Integer;

Begin
  n := Nums[2];
  LibCount := n;
End.
