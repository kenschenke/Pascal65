(* Test 20 - Array inside record
NEW IWS 14
DIA LBL xxxxx
DIR LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
PSH IWU 3039
PSH VDR 14 1 0
PSH IBS 4
ADD IBS 3 IBS 3 IBS 3
PSH IBS 2
AIX IBS 2
SET IBS 4 IBS 4
DAT IBU 5 LBL xxxxx
   heap offset: 4
   low bound: 1
   high bound: 5
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 20
   fields:
      offset: 4, ARRAY, xxxxx
*)

Program Test;

Type
   MyRecord = Record
      i, j : Integer;
      arr : Array[1..5] Of Integer;
   End;

Var
   rec : MyRecord;

Begin
   rec.arr[2] := 12345;
End.
