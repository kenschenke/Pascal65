(* Test 48 - String comparisons
HDR PRG test 0 200 8
IMP LIB system 22
   RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
SST ILS 0
SST ILS 0
NEW IWS c
DIA LBL xxxxx
DIR LBL xxxxx
NEW IWS c
DIA LBL xxxxx
NEW IWS a
DIA LBL xxxxx
NEW IWS b
DIA LBL xxxxx
PSH CHR 
PSH BOO 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH CHR f
PSH RET 
SET IBS 15 IBS 9
PSH RET 
PSH CHR g
LST IBS 15 IBS 9
PSH VDW 8 1 7
SET IBS 8 IBS 8
RTS
LOC LBL xxxxx
PSH VVR 15 2 0
MEM IBS 15
PSH VDR 15 2 1
LSE IBS 15 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
RTS
LOC LBL xxxxx
PSH VDR 15 1 0
PSH VDR 15 1 1
EQU IBS 15 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PSH VDR 15 1 1
NEQ IBS 15 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PSH VDR 15 1 1
LST IBS 15 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PSH VDR 15 1 1
LSE IBS 15 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PSH VDR 15 1 1
GRT IBS 15 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PSH VDR 15 1 1
GTE IBS 15 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 14 1 2
MEM IBS 15
PSH VDR 15 1 0
EQU IBS 15 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR b 1 3
PSH IBS 2
AIX IBS 2
MEM IBS 15
PSH VDR 15 1 0
NEQ IBS 15 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PSH STR lit
LST IBS 15 IBS a
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH STR lit
PSH VDR 15 1 0
GRT IBS a IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PSH VDR 15 1 0
PSH VDR 15 1 1
CCT IBS 15 IBS 15
EQU IBS 15 IBS 16
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PSH VDR 15 1 1
CCT IBS 15 IBS 15
PSH VDR 15 1 0
NEQ IBS 16 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PUF IBS 2 LBL xxxxx
PSH IBS 1
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDR 15 1 0
GTE IBS 16 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PUF IBS 2 LBL xxxxx
PSH IBS 2
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
LSE IBS 15 IBS 16
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR b 1 4
PSH VDR 15 1 0
EQU IBS b IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 14 1 2
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS b
PSH VDR b 1 5
NEQ IBS b IBS b
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 9 1 6
PSH VDR 15 1 0
LST IBS 9 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 15 1 0
PSH CHR x
GRT IBS 15 IBS 9
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH IBS 1
PSH VDR 15 1 0
SSR
PSH CHR x
EQU IBS 9 IBS 9
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH IBS 1
PSH VDR 15 1 0
SSR
PSH VDR 15 1 0
NEQ IBS 9 IBS 15
PSH VDW 8 1 7
SET IBS 8 IBS 8
PSH VDR 9 1 6
PSH CHR y
EQU IBS 9 IBS 9
PSH VDW 8 1 7
SET IBS 8 IBS 8
DAT IBU 5 LBL xxxxx
   heap offset: 2
   low bound: 1
   high bound: 4
   elem size: 1
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 12
   fields:
      offset: 0, STRING
      offset: 2, ARRAY, xxxxx
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 3
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 4
   elem size: 1
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: -2
   high bound: 2
   elem size: 1
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
EOM IBU 0
*)

// Each comparison reads its operands and gives EQU through GTE the kind
// the runtime reads each by: String variable (21), string object (22),
// literal (10), array (11) or Char (9). A function's String result is a
// string object, which the runtime frees, as a concatenation is. A
// character of a String (SSR) is a Char, so s[1] = 'x' stays ordinal.

Program Test;

Type
  Rec = Record
    s : String;
    a : Array[1..4] Of Char;
  End;

Var
  s, t : String;
  r : Rec;
  e : Array[1..3] Of String;
  ac : Array[1..4] Of Char;
  ab : Array[-2..2] Of Char;
  c : Char;
  b : Boolean;

Function F(n : Integer) : String;
Begin
  F := 'f';
  b := F < 'g';
End;

Procedure P(Var vs : String; ws : String);
Begin
  b := vs <= ws;
End;

Begin
  b := s = t;
  b := s <> t;
  b := s < t;
  b := s <= t;
  b := s > t;
  b := s >= t;
  b := r.s = s;
  b := e[2] <> s;
  b := s < 'lit';
  b := 'lit' > s;
  b := s = s + t;
  b := s + t <> s;
  b := F(1) >= s;
  b := s <= F(2);
  b := ac = s;
  b := r.a <> ab;
  b := c < s;
  b := s > 'x';
  b := s[1] = 'x';
  b := s[1] <> s;
  b := c = 'y';
End.
