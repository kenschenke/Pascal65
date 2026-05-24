(* Test 19 - Array literals
NEW IWS 10
DIA LBL xxxxx
NEW IWS 36
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
DAT IBU 0 LBL xxxxx
   10 00 20 00 30 00 
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 5
   elem size: 2
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 3
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 16
   elem type: 5
   elem label: xxxxx
   literals: 
   num literals: 0
DAT IBU 0 LBL xxxxx
   11 00 21 00 31 00 
DAT IBU 5 LBL xxxxx
   heap offset: 6
   low bound: 1
   high bound: 5
   elem size: 2
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 3
DAT IBU 0 LBL xxxxx
   12 00 22 00 32 00 42 00 
DAT IBU 5 LBL xxxxx
   heap offset: 22
   low bound: 1
   high bound: 5
   elem size: 2
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 4
DAT IBU 0 LBL xxxxx
   13 00 23 00 33 00 43 00 53 00 
DAT IBU 5 LBL xxxxx
   heap offset: 38
   low bound: 1
   high bound: 5
   elem size: 2
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 5
*)

Program Test;

Var
  arr1 : Array[1..5] Of Integer = ($10, $20, $30);
  arr2 : Array[1..3,1..5] Of Integer =
    ( ($11, $21, $31), ($12, $22, $32, $42), ($13, $23, $33, $43, $53) );

Begin
End.
