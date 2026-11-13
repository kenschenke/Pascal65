(* Test 31 - Forward declarations, value parameters and local variables
NEW IWS c
DIA LBL xxxxx
SST ILS 0
PSH IWU 0
NEW IWS c
DIA LBL xxxxx
DIR LBL xxxxx
NEW IWS 1e
DIA LBL xxxxx
DIA LBL xxxxx
DIA LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH VDR b 2 0
PSH IBS 1
AIX IBS 2
MEM IBS 4
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
RTS
LOC LBL xxxxx
NEW IWS c
DIA LBL xxxxx
NEW IWS 4
DIR LBL xxxxx
SST ILS 0
PSH ILS 0
PSH IWU 0
PSH VDR b 2 0
PSH IBS 1
AIX IBS 2
MEM IBS 4
PSH VDR 14 2 1
MEM IBS 4
ADD IBS 4 IBS 4 IBS 4
PSH VDW 4 2 4
SET IBS 4 IBS 4
POP
DEF
DEL
DEL
DCF LBL xxxxx IBS 5
RTS
LOC LBL xxxxx
PSH IBS 1
PSH VVW 4 2 0
SET IBS 4 IBS 2
PSH VVR 4 2 0
MEM IBS 4
PSH IBS 3
GRT IBS 4 IBS 2
BIT LBL xxxxx
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH VVR 4 2 0
MEM IBS 4
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VVR 4 2 0
MEM IBS 4
PSH IBS 3
EQU IBS 4 IBS 2
BIT LBL xxxxx
PSH VVR 4 2 0
MEM IBS 4
SUC IBS 4
PSH VVW 4 2 0
SET IBS 4 IBS 4
BRA LBL xxxxx
LOC LBL xxxxx
RTS
LOC LBL xxxxx
PSH VDR 4 2 0
PSH VDW 4 1 2
SET IBS 4 IBS 4
RTS
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH VDR b 1 0
DCC LBL xxxxx IBS 5
PSH VDR 15 1 1
SCV IBS 15
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
DEL
DCF LBL xxxxx IBS 5
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH VDW 4 1 2
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 14 1 3
MEM IBS 4
PSH VDW 4 1 2
SET IBS 4 IBS 4
PSH VDR b 1 4
PSH IBS 2
AIX IBS 2
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
PSH VDW 4 1 2
SET IBS 4 IBS 4
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 12
   fields:
      offset: 0, ARRAY, xxxxx
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
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 4
*)

// An array or string passed by value is copied, and the copy is freed
// after the call. A routine's local arrays, records, strings and files
// are freed when it returns. A Var parameter can be a For loop's control
// variable. Low and High of an array in a record or another array.

Program Test;

Type
  IntArray = Array[1..3] Of Integer;
  Point = Record
    x, y : Integer;
  End;
  ArrRec = Record
    a : IntArray;
  End;

Var
  arr : IntArray;
  s : String;
  i : Integer;
  ar : ArrRec;
  grid : Array[1..2] Of IntArray;

Procedure Later(n : Integer); Forward;

Procedure ByValue(a : IntArray; str : String);
Begin
  Later(a[1]);
End;

Procedure Locals;
Var
  la : IntArray;
  lr : Point;
  ls : String;
  lf : Text;
  li : Integer;
Begin
  li := la[1] + lr.x;
End;

Procedure Loop(Var n : Integer);
Begin
  For n := 1 To 3 Do Later(n);
End;

Procedure Later(n : Integer);
Begin
  i := n;
End;

Begin
  ByValue(arr, s);
  Locals;
  Loop(i);
  i := Low(ar.a);
  i := High(grid[2]);
End.
