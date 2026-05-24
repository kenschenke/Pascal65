(* Test 15 - Array Literals
NEW IWS 10
DIA LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
DAT IBU 0 LBL xxxxx
   57 04 ae 08 05 0d 5c 11 b3 15 
DAT IBU 5 LBL xxxxx
   heap offset: 0
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
  arr : Array[1..5] Of Integer = (1111, 2222, 3333, 4444, 5555);

Begin
End.
