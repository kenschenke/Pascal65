(* Test 7 - Case Statement
PSH IWU 0
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
LOC LBL xxxxx
PSH VDR 4 1 0
PSH IBS 1
EQU IBS 4 IBS 2
BIT LBL xxxxx
PSH VDR 4 1 0
PSH IBS 2
EQU IBS 4 IBS 2
BIT LBL xxxxx
PSH VDR 4 1 0
PSH IBS 3
EQU IBS 4 IBS 2
BIT LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 9
PSH VDW 4 1 1
SET IBS 4 IBS 2
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 4 1 0
PSH IBS 4
EQU IBS 4 IBS 2
BIT LBL xxxxx
PSH VDR 4 1 0
PSH IBS 5
EQU IBS 4 IBS 2
BIT LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS a
PSH VDW 4 1 1
SET IBS 4 IBS 2
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 4 1 0
PSH IBS 6
EQU IBS 4 IBS 2
BIT LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 8
PSH VDW 4 1 1
SET IBS 4 IBS 2
LOC LBL xxxxx
*)

Program Test;

Var
    i, j : Integer;

Begin
  Case i Of
    1, 2, 3: j := 9;
    4, 5: Begin
      j := 10;
    End;
    6: j := 8;
  End;
End.
