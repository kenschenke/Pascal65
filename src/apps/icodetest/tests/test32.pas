(* Test 32 - Array bounds and element types
NEW IWS b
DIA LBL xxxxx
NEW IWS 14
DIA LBL xxxxx
NEW IWS 9
DIA LBL xxxxx
NEW IWS c
DIA LBL xxxxx
NEW IWS e
DIA LBL xxxxx
NEW IWS e
DIA LBL xxxxx
NEW IWS a
DIA LBL xxxxx
NEW IWS e
DIA LBL xxxxx
NEW IWS c
DIA LBL xxxxx
NEW IWS 132
DIA LBL xxxxx
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH IWS 12c
PSH VDW 4 1 a
SET IBS 4 IBS 4
PSH IBS 1
PSH VDR b 1 0
PSH CHR b
AIX IBS 9
SET IBS 1 IBS 2
PSH VDR 4 1 a
PSH VDR b 1 1
PSH IBS fe
AIX IBS 2
SET IBS 4 IBS 4
PSH VDR 4 1 a
PSH VDR b 1 3
PSH IWU 1
AIX IBS 13
SET IBS 4 IBS 4
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 65
   high bound: 69
   elem size: 1
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: -3
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: -300
   high bound: -298
   elem size: 1
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
   low bound: 1
   high bound: 2
   elem size: 4
   elem type: 4
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 2
   elem size: 4
   elem type: 4
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 2
   elem size: 2
   elem type: 3
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 2
   elem size: 4
   elem type: 1
   elem label: 
   literals: 
   num literals: 0
DAT IBU 3 LBL xxxxx
   a
   bc
   d
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 3
   elem label: 
   literals: xxxxx
   num literals: 3
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 300
   elem size: 1
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
*)

// Character, negative and enumeration bounds, arrays of files, strings
// and reals with no literals, string literals of one character and the
// Length of an array with more than 255 elements.

Program Test;

Type
  Colors = (Red, Green, Blue);

Var
  letters : Array['a'..'e'] Of Byte;
  neg : Array[-3..3] Of Integer;
  wneg : Array[-300..-298] Of Byte;
  byColor : Array[Red..Blue] Of Integer;
  texts : Array[1..2] Of Text;
  files : Array[1..2] Of File Of Integer;
  names : Array[1..2] Of String;
  reals : Array[1..2] Of Real;
  words : Array[1..3] Of String = ('a', 'bc', 'd');
  big : Array[1..300] Of Byte;
  i : Integer;

Begin
  i := Length(big);
  letters['b'] := 1;
  neg[-2] := i;
  byColor[Green] := i;
End.
