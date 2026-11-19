(* Test 40 - More than 32 globals after a file variable
HDR PRG test 0 200
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
PSH ILS 0
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
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 1
PSH VDW 4 1 28
SET IBS 4 IBS 2
EOM IBU 2
*)

// The globals' cleanup entries once went in fixed 32-entry arrays that
// overflowed into the overlay's variables, and the 38th declaration
// cleared runtimeFeatures: the file variable's RTF_FILES was lost
// (expectedFeatures). Globals aren't freed, so nothing is recorded now.

Program Test;

Var
  f : Text;
  g1 : Integer;
  g2 : Integer;
  g3 : Integer;
  g4 : Integer;
  g5 : Integer;
  g6 : Integer;
  g7 : Integer;
  g8 : Integer;
  g9 : Integer;
  g10 : Integer;
  g11 : Integer;
  g12 : Integer;
  g13 : Integer;
  g14 : Integer;
  g15 : Integer;
  g16 : Integer;
  g17 : Integer;
  g18 : Integer;
  g19 : Integer;
  g20 : Integer;
  g21 : Integer;
  g22 : Integer;
  g23 : Integer;
  g24 : Integer;
  g25 : Integer;
  g26 : Integer;
  g27 : Integer;
  g28 : Integer;
  g29 : Integer;
  g30 : Integer;
  g31 : Integer;
  g32 : Integer;
  g33 : Integer;
  g34 : Integer;
  g35 : Integer;
  g36 : Integer;
  g37 : Integer;
  g38 : Integer;
  g39 : Integer;
  g40 : Integer;

Begin
  g40 := 1;
End.
