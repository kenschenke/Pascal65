(* Test 38 - Whole records from elements, fields and pointers
NEW IWS 4
DIR LBL xxxxx
NEW IWS 12
DIR LBL xxxxx
DIR LBL xxxxx
DIR LBL xxxxx
DIA LBL xxxxx
PSH IWU 0
NEW IWS 8
DIR LBL xxxxx
PSH IBS 0
PSH CHR 
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR b 1 1
PSH IBS 2
AIX IBS 2
PSH VDW 14 1 0
SET IBS 14 IBS 14
PSH VDR 1b 1 2
PSH VDW 14 1 0
SET IBS 14 IBS 14
PSH VDR 14 1 3
PSH IBS 4
ADD IBS 3 IBS 3 IBS 3
PSH VDW 14 1 0
SET IBS 14 IBS 14
PSH VDR b 1 1
PSH IBS 3
AIX IBS 2
PSH VDW 1b 1 2
SET IBS 1b IBS 1c
PUF IBS 2 LBL xxxxx
PSH VDR 1 1 4
CVI IBS 1 IBS 5
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 1 1 4
SET IBS 1 IBS 1
PUF IBS 2 LBL xxxxx
PSH VDR 1 1 4
CVI IBS 1 IBS 5
PSH VDR 1 1 4
CVI IBS 1 IBS 3
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POP
POP
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH VDR 1 1 4
CVI IBS 1 IBS 4
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 9 1 5
SET IBS 9 IBS 9
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 4
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 4
   elem type: 2
   elem label: xxxxx
   literals: 
   num literals: 0
DAT IBU 2 LBL xxxxx
   heap offset: 6
   rec size: 4
DAT IBU 2 LBL xxxxx
   heap offset: 12
   rec size: 4
DAT IBU 2 LBL xxxxx
   heap offset: 18
   rec size: 4
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 4
DAT IBU 2 LBL xxxxx
   heap offset: 10
   rec size: 4
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 8
   fields:
      offset: 0, RECORD, xxxxx
      offset: 4, RECORD, xxxxx
*)

// A record in an array or another record, or that a pointer points to,
// is at its address, like a record variable's heap address, so reading
// it has no MEM. A Byte passed to a library's Cardinal, Word and Integer
// parameters is converted.

Program Test;

Type
  Point = Record
    x, y : Integer;
  End;
  Line = Record
    a, b : Point;
  End;

Var
  pt : Point;
  pts : Array[1..3] Of Point;
  pp : ^Point;
  ln : Line;
  b : Byte;
  ch : Char;

Begin
  pt := pts[2];
  pt := pp^;
  pt := ln.b;
  pp := @pts[3];
  b := Peek(b);
  PokeW(b, b);
  ch := Chr(b);
End.
