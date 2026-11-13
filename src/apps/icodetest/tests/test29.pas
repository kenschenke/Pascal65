(* Test 29 - Comparisons, pointer arithmetic, Inc and Dec, Round
PSH IWU 0
PSH IWU 0
PSH BOO 0
PSH IWU 0
PSH IWU 0
PSH CHR 
PSH FLT 
PSH IWU 0
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 4 1 0
PSH VDR 4 1 1
EQU IBS 4 IBS 4
PSH VDW 8 1 2
SET IBS 8 IBS 8
PSH VDR 12 1 3
PSH VDR 12 1 4
EQU IBS 3 IBS 3
PSH VDW 8 1 2
SET IBS 8 IBS 8
PSH VDR 12 1 3
PSH IWU 2
LST IBS 3 IBS 3
PSH VDW 8 1 2
SET IBS 8 IBS 8
PSH IWU 1
PSH VDR 12 1 4
GTE IBS 3 IBS 3
PSH VDW 8 1 2
SET IBS 8 IBS 8
PSH VDR 4 1 0
PSH IBS 1
EQU IBS 4 IBS 2
BIF LBL xxxxx
PSH IBS 2
PSH VDW 4 1 0
SET IBS 4 IBS 2
LOC LBL xxxxx
PSH VDR 12 1 3
PSH IWU 0
NEQ IBS 3 IBS 3
BIF LBL xxxxx
PSH IBS 3
PSH VDW 4 1 0
SET IBS 4 IBS 2
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 2
LOC LBL xxxxx
PSH VDR 1b 1 7
PSH IBS 1
PSH IWS 2
MUL IBS 2 IBS 4 IBS 4
ADD IBS 1b IBS 4 IBS 1c
PSH VDW 1b 1 7
SET IBS 1b IBS 1c
PSH VDR 1b 1 7
PSH VDR 4 1 1
PSH IWS 2
MUL IBS 4 IBS 4 IBS 4
SUB IBS 1b IBS 4 IBS 1c
PSH VDW 1b 1 7
SET IBS 1b IBS 1c
PSH VDR 1b 1 8
PSH VDR 4 1 0
PSH IWS 4
MUL IBS 4 IBS 4 IBS 4
ADD IBS 1b IBS 4 IBS 1c
PSH VDW 1b 1 8
SET IBS 1b IBS 1c
PSH VDR 9 1 5
PSH IBS 1
ADD IBS 2 IBS 1 IBS 2
PSH VDW 9 1 5
SET IBS 2 IBS 2
PSH VDR 12 1 3
PSH IBS 1
SUB IBS 4 IBS 1 IBS 4
PSH VDW 12 1 3
SET IBS 4 IBS 4
PSH VDR 7 1 6
ROU
PSH VDW 4 1 0
SET IBS 4 IBS 4
PSH VDR 7 1 6
TRU
PSH VDW 4 1 0
SET IBS 4 IBS 4
*)

// An enumeration is compared as a Word. Adding to or subtracting from a
// pointer multiplies the right side by the size of what it points to.
// Inc and Dec of a Char are done as a ShortInt and of an enumeration as
// an Integer. An If with no Else branches to the end of the If.

Program Test;

Type
  Colors = (Red, Green, Blue);

Var
  i, j : Integer;
  b : Boolean;
  c, d : Colors;
  ch : Char;
  r : Real;
  p : ^Integer;
  lp : ^LongInt;

Begin
  b := i = j;
  b := c = d;
  b := c < Blue;
  b := Green >= d;
  If i = 1 Then i := 2;
  If c <> Red Then
    i := 3
  Else
    i := 4;
  p := p + 1;
  p := p - j;
  lp := lp + i;
  Inc(ch);
  Dec(c);
  i := Round(r);
  i := Trunc(r);
End.
