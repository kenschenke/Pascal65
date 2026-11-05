(* Test 27 - Dynamic arrays
NEW IWS 6
DIA LBL xxxxx
NEW IWS 10
DIA LBL xxxxx
NEW IWS 9
DIA LBL xxxxx
NEW IWS 6
DIA LBL xxxxx
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH VVW b 2 0
PSH IBS 3
CVI IBS 2 IBS 6
SAL LBL xxxxx
RTS
LOC LBL xxxxx
PSH VDW b 1 0
PSH IBS a
CVI IBS 2 IBS 6
SAL LBL xxxxx
PSH VDW b 1 3
PSH VDR 4 1 4
CVI IBS 4 IBS 6
SAL LBL xxxxx
PSH VDR b 1 0
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
PSH IBS 1
ADD IBS 4 IBS 1 IBS 4
PSH VDW 4 1 4
SET IBS 4 IBS 4
PSH IWS 5
PSH VDW 4 1 4
SET IBS 4 IBS 4
PSH VDR b 1 2
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
PSH IBS 1
ADD IBS 4 IBS 1 IBS 4
PSH VDW 4 1 4
SET IBS 4 IBS 4
PSH VDR b 1 0
MEM IBS 4
PSH VDW 4 1 4
SET IBS 4 IBS 4
PSH VDR b 1 1
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
PSH VDW 4 1 4
SET IBS 4 IBS 4
PUF IBS 2 LBL xxxxx
PSH VDW b 1 0
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: -1
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 5
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 0 LBL xxxxx
   41 42 43 
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: 2
   elem size: 1
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 3
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: -1
   elem size: 4
   elem type: 2
   elem label: xxxxx
   literals: 
   num literals: 0
DAT IBU 2 LBL xxxxx
   heap offset: 6
   rec size: 4
   fields:
      offset: 0, STRING
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: -1
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
*)

// SetLength writes SAL with the label of the array's declaration block,
// after the array's variable reference and the new length as a LongInt.
// A parameter's block is written with its routine. Length of a static
// array is a constant. A dynamic array's Length is High + 1. A dynamic
// array of records has a block for its first element but no DIR.

Program Test;

Type
  TRec = Record
    s : String;
    n : Integer;
  End;

Var
  a : Array Of Integer;
  s : Array[1..5] Of Integer;
  c : Array Of Char = ('a', 'b', 'c');
  r : Array Of TRec;
  n : Integer;

Procedure P(Var d : Array Of Integer);
Begin
  SetLength(d, 3);
End;

Begin
  SetLength(a, 10);
  SetLength(r, n);
  n := Length(a);
  n := Length(s);
  n := Length(c);
  n := Low(a);
  n := High(s);
  P(a);
End.
