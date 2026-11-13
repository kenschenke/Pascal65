(* Test 33 - Typed files of records and arrays
PSH ILS 0
PSH ILS 0
NEW IWS 4
DIR LBL xxxxx
NEW IWS c
DIA LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
SFH IBS 80 IBS 0
ONL
SFH IBS 0 IBS 0
PSH VDR 17 1 0
SFH IBS 82 IBS 0
PSH VDR 14 1 2
PSH IWS 4
OUT IBS 1a
SFH IBS 0 IBS 0
PSH VDR 17 1 1
SFH IBS 82 IBS 0
PSH VDR b 1 3
PSH IWS c
OUT IBS 1a
SFH IBS 0 IBS 0
PSH VDR 17 1 0
SFH IBS 82 IBS 1
PSH VDR 14 1 2
PSH IWS 4
INP IBS 1a
SFH IBS 0 IBS 1
PSH VDR 17 1 1
SFH IBS 82 IBS 1
PSH VDR b 1 3
PSH IWS c
INP IBS 1a
SFH IBS 0 IBS 1
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 4
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
*)

// A record or array is written to and read from a typed file as bytes
// on the heap. Writeln with no arguments writes a new line.

Program Test;

Type
  Point = Record
    x, y : Integer;
  End;
  Trio = Array[1..3] Of Integer;

Var
  pf : File Of Point;
  af : File Of Trio;
  p : Point;
  a : Trio;

Begin
  Writeln;
  Write(pf, p);
  Write(af, a);
  Read(pf, p);
  Read(af, a);
End.
