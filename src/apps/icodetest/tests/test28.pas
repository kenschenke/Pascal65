(* Test 28 - Unary minus
PSH IBS 0
PSH IBS 0
PSH IWU 0
PSH IWU 0
PSH ILS 0
PSH ILS 0
PSH FLT 
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 2 1 0
NEG IBS 2
PSH VDW 2 1 0
SET IBS 2 IBS 2
PSH VDR 1 1 1
CVI IBS 1 IBS 4
NEG IBS 4
PSH VDW 4 1 2
SET IBS 4 IBS 4
PSH VDR 3 1 3
CVI IBS 3 IBS 6
NEG IBS 6
PSH VDW 6 1 4
SET IBS 6 IBS 6
PSH VDR 5 1 5
CVI IBS 5 IBS 6
NEG IBS 6
PSH VDW 6 1 4
SET IBS 6 IBS 6
PSH VDR 7 1 6
NEG IBS 7
PSH VDW 7 1 6
SET IBS 7 IBS 7
PSH FLT 2.5
NEG IBS 7
PSH VDW 7 1 6
SET IBS 7 IBS 7
PSH VDR 4 1 2
NEG IBS 4
PSH VDR 4 1 2
NEG IBS 4
MUL IBS 4 IBS 4 IBS 4
PSH VDW 4 1 2
SET IBS 4 IBS 4
*)

// A negated unsigned operand is converted to the signed type first. A
// real literal is pushed as text, so a negative one is negated after.

Program Test;

Var
  s : ShortInt;
  b : Byte;
  i : Integer;
  w : Word;
  l : LongInt;
  c : Cardinal;
  r : Real;

Begin
  s := -s;
  i := -b;
  l := -w;
  l := -c;
  r := -r;
  r := -2.5;
  i := -i * -i;
End.
