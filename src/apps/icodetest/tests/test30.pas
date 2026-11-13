(* Test 30 - Fields, pointers, string subscripts and file fields
SST STR Hello
NEW IWS 12
DIR LBL xxxxx
DIR LBL xxxxx
DIR LBL xxxxx
DIA LBL xxxxx
NEW IWS 1e
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
PSH IWU 0
PSH IWU 0
SST STR Hello
PSH CHR 
PSH IWU 0
PSH IWU 0
NEW IWS a
DIR LBL xxxxx
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 5
PSH VDR b 1 1
PSH IBS 2
AIX IBS 2
SET IBS 4 IBS 2
PSH VDR b 1 1
PSH IBS 3
AIX IBS 2
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
PSH VDW 4 1 a
SET IBS 4 IBS 4
PSH IBS 7
PSH VDR 1b 1 3
SET IBS 4 IBS 2
PSH VDR 1b 1 3
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
PSH VDW 4 1 a
SET IBS 4 IBS 4
PSH VDR 1b 1 3
PSH VDR b 1 1
PSH IBS 1
AIX IBS 2
SET IBS 14 IBS 14
PSH VDR 1b 1 4
MEM IBS 15
PSH VDW 15 1 5
SET IBS 15 IBS 15
PSH CHR J
PSH VDR 15 1 5
PSH IBS 1
SSW
SET IBS 9 IBS 9
PSH IBS 2
PSH VDR 15 1 5
SSR
PSH VDW 9 1 6
SET IBS 9 IBS 9
PSH VDR 12 1 7
PSH VDW 12 1 8
SET IBS 12 IBS 13
PSH VDR b 1 2
PSH IBS 1
AIX IBS 2
PSH IBS 2
AIX IBS 2
MEM IBS 4
PSH VDW 4 1 a
SET IBS 4 IBS 4
PSH VDR 4 1 a
PSH VDR b 1 2
PSH IBS 2
AIX IBS 2
PSH IBS 3
AIX IBS 2
SET IBS 4 IBS 4
PSH IBS 1
PSH VDR 14 1 9
PSH IBS 8
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 2
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
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 2
   elem size: 12
   elem type: 5
   elem label: xxxxx
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 6
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 18
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 10
   fields:
      offset: 0, FILE
      offset: 4, FILE
*)

// A field of an array element and of a pointer's record, a record and a
// string read through a pointer, string subscripts, an enumeration
// subrange, an array of arrays, a record with file fields and a string
// initialized from a constant.

Program Test;

Const
  Greeting = 'Hello';

Type
  Colors = (Red, Green, Blue, Yellow);
  Point = Record
    x, y : Integer;
  End;
  PointPtr = ^Point;
  FileRec = Record
    t : Text;
    f : File Of Integer;
    n : Integer;
  End;

Var
  pts : Array[1..3] Of Point;
  grid : Array[1..2] Of Array[1..3] Of Integer;
  pp : PointPtr;
  sp : ^String;
  s : String = Greeting;
  ch : Char;
  sub : Green..Blue;
  c : Colors;
  fr : FileRec;
  i : Integer;

Begin
  pts[2].x := 5;
  i := pts[3].y;
  pp^.x := 7;
  i := pp^.y;
  pts[1] := pp^;
  s := sp^;
  s[1] := 'J';
  ch := s[2];
  c := sub;
  i := grid[1][2];
  grid[2][3] := i;
  fr.n := 1;
End.
