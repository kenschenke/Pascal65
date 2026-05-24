(* Test 8 - Arrays
NEW IWS 10
DIA LBL xxxxx
NEW IWS 56
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
PSH IWU 0
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 5
PSH VDR b 1 0
PSH IBS 3
AIX IBS 2
SET IBS 4 IBS 2
PSH IBS 6
PSH VDR b 1 0
PSH VDR 4 1 2
PSH IBS 1
ADD IBS 4 IBS 1 IBS 6
AIX IBS 6
SET IBS 4 IBS 2
PSH IBS 2
PSH VDR b 1 1
PSH IBS 3
AIX IBS 2
PSH IBS 5
AIX IBS 2
SET IBS 4 IBS 2
PSH IBS 7
PSH VDR b 1 1
PSH VDR 4 1 2
PSH IBS 1
ADD IBS 4 IBS 1 IBS 6
AIX IBS 6
PSH VDR 4 1 2
PSH IBS 3
MUL IBS 4 IBS 1 IBS 6
AIX IBS 6
SET IBS 4 IBS 2
PSH IBS 8
PSH VDR b 1 1
PSH VDR 4 1 2
AIX IBS 4
PSH VDR 4 1 3
PSH IBS 1
ADD IBS 4 IBS 1 IBS 6
AIX IBS 6
SET IBS 4 IBS 2
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 5
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: 4
   elem size: 16
   elem type: 5
   elem label: xxxxx
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 6
   low bound: 0
   high bound: 4
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 22
   low bound: 0
   high bound: 4
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 38
   low bound: 0
   high bound: 4
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 54
   low bound: 0
   high bound: 4
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 70
   low bound: 0
   high bound: 4
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
*)

Program Test;

Var
  arr1 : Array[1..5] Of Integer;
  arr2 : Array[5,5] Of Integer;
  i, j : Integer;

Begin
  arr1[3] := 5;
  arr1[i+1] := 6;
  arr2[3,5] := 2;
  arr2[i+1,i*3] := 7;
  arr2[i][j+1] := 8;
End.
