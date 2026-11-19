(* Test 41 - A routine with more than 32 locals
HDR PRG test 0 200 0
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
BRA LBL xxxxx
LOC LBL xxxxx
NEW IWS c
DIA LBL xxxxx
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH IWU 0
PSH VDR b 2 0
PSH IBS 2
AIX IBS 2
MEM IBS 4
PSH VDW 4 2 28
SET IBS 4 IBS 4
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
POP
DCF LBL xxxxx IBS 5
RTS
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POF IBS 0 IBS 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
EOM IBU 0
*)

// A routine's locals once went in fixed 32-entry arrays on the compiler's
// stack. The 33rd overwrote the routine's own declaration pointer and icode
// hung. They're now on the heap, sized to the routine (countLocals), and
// the cleanup frees each one: 40 POPs, then the array's DCF.

Program Test;

Procedure Many;
Var
  a : Array[1..3] Of Integer;
  l1 : Integer;
  l2 : Integer;
  l3 : Integer;
  l4 : Integer;
  l5 : Integer;
  l6 : Integer;
  l7 : Integer;
  l8 : Integer;
  l9 : Integer;
  l10 : Integer;
  l11 : Integer;
  l12 : Integer;
  l13 : Integer;
  l14 : Integer;
  l15 : Integer;
  l16 : Integer;
  l17 : Integer;
  l18 : Integer;
  l19 : Integer;
  l20 : Integer;
  l21 : Integer;
  l22 : Integer;
  l23 : Integer;
  l24 : Integer;
  l25 : Integer;
  l26 : Integer;
  l27 : Integer;
  l28 : Integer;
  l29 : Integer;
  l30 : Integer;
  l31 : Integer;
  l32 : Integer;
  l33 : Integer;
  l34 : Integer;
  l35 : Integer;
  l36 : Integer;
  l37 : Integer;
  l38 : Integer;
  l39 : Integer;
  l40 : Integer;
Begin
  l40 := a[2];
End;

Begin
  Many;
End.
