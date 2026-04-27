(* Test 18 - Write, Writeln, Writestr
PSH BOO 0
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 8 1 0
BIF LBL xxxxx
PSH IWU 4d2
PSH VDW 4 1 1
SET IBS 4 IBS 4
BRA LBL xxxxx
LOC LBL xxxxx
PSH IWU 929
PSH VDW 4 1 1
SET IBS 4 IBS 4
LOC LBL xxxxx
*)

Program Test;

Var
  bool : Boolean;
  i : Integer;

Begin
  If bool Then
    i := 1234
  Else
    i := 2345;
End.
