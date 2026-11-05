(* Test 26 - For loop with a subrange control variable
PSH CHR 
PSH CHR 
BRA LBL xxxxx
LOC LBL xxxxx
PSH CHR b
PSH VDW 11 1 0
SET IBS 9 IBS 9
PSH VDR 11 1 0
PSH CHR d
GRT IBS 9 IBS 9
BIT LBL xxxxx
LOC LBL xxxxx
PSH VDR 11 1 0
PSH VDW 9 1 1
SET IBS 9 IBS 9
PSH VDR 11 1 0
PSH CHR d
EQU IBS 9 IBS 9
BIT LBL xxxxx
PSH VDR 11 1 0
SUC IBS 9
PSH VDW 9 1 0
SET IBS 9 IBS 9
BRA LBL xxxxx
LOC LBL xxxxx
*)

// The compare, Succ and the store of the control variable use the kind of
// its base type, Char (9), and not the kind of its own type, subrange (11).

Program Test;

Type
  Letters = 'a'..'e';

Var
  l : Letters;
  c : Char;

Begin
  For l := 'b' To 'd' Do
    c := l;
End.
