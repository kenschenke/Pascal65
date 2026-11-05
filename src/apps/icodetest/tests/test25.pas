(* Test 25 - Arrays indexed by a declared type
PSH IBS 4
NEW IWS 10
DIA LBL xxxxx
NEW IWS c
DIA LBL xxxxx
NEW IWS e
DIA LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 5
   high bound: 9
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: 2
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
*)

// The bounds of an array indexed by a subrange, an enumeration or a
// constant declared in the Type and Const sections come from that
// declaration: Range is 5..9, Color is 0..2 and Count elements are 0..3.

Program Test;

Const
   Count = 4;

Type
   Range = 5..9;
   Color = (Red, Green, Blue);

Var
   a : Array[Range] Of Integer;
   c : Array[Color] Of Integer;
   k : Array[Count] Of Integer;

Begin
End.
