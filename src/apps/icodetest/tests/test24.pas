(* Test 24 - Three level array literal
NEW IWS 48
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 22
   elem type: 5
   elem label: xxxxx
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 6
   low bound: 1
   high bound: 2
   elem size: 8
   elem type: 5
   elem label: xxxxx
   literals: 
   num literals: 0
DAT IBU 0 LBL xxxxx
   41 42 
DAT IBU 5 LBL xxxxx
   heap offset: 12
   low bound: 1
   high bound: 2
   elem size: 1
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 2
DAT IBU 0 LBL xxxxx
   43 44 
DAT IBU 5 LBL xxxxx
   heap offset: 20
   low bound: 1
   high bound: 2
   elem size: 1
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 2
DAT IBU 5 LBL xxxxx
   heap offset: 28
   low bound: 1
   high bound: 2
   elem size: 8
   elem type: 5
   elem label: xxxxx
   literals: 
   num literals: 0
DAT IBU 0 LBL xxxxx
   45 46 
DAT IBU 5 LBL xxxxx
   heap offset: 34
   low bound: 1
   high bound: 2
   elem size: 1
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 2
DAT IBU 0 LBL xxxxx
   47 48 
DAT IBU 5 LBL xxxxx
   heap offset: 42
   low bound: 1
   high bound: 2
   elem size: 1
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 2
DAT IBU 5 LBL xxxxx
   heap offset: 50
   low bound: 1
   high bound: 2
   elem size: 8
   elem type: 5
   elem label: xxxxx
   literals: 
   num literals: 0
DAT IBU 0 LBL xxxxx
   49 4a 
DAT IBU 5 LBL xxxxx
   heap offset: 56
   low bound: 1
   high bound: 2
   elem size: 1
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 2
DAT IBU 0 LBL xxxxx
   4b 4c 
DAT IBU 5 LBL xxxxx
   heap offset: 64
   low bound: 1
   high bound: 2
   elem size: 1
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 2
*)

Program Test;

Var
  t : Array[1..3] Of Array[1..2] Of Array[1..2] Of Char =
    ((('a', 'b'), ('c', 'd')), (('e', 'f'), ('g', 'h')),
     (('i', 'j'), ('k', 'l')));

Begin
End.
