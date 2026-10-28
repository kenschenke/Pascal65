(* Test 23 - Type casts
PSH IBS 0
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 4 1 1
CVI IBS 4 IBS 1
PSH VDW 1 1 0
SET IBS 1 IBS 1
PSH VDR 1 1 0
CVI IBS 1 IBS 4
PSH VDW 4 1 1
SET IBS 4 IBS 4
PSH VDR 1 1 0
CVI IBS 1 IBS 4
PSH IBS c8
ADD IBS 4 IBS 1 IBS 4
PSH VDW 4 1 1
SET IBS 4 IBS 4
PSH VDR 1 1 0
CVI IBS 1 IBS 4
PSH VDW 4 1 1
SET IBS 4 IBS 4
PSH IBS c8
PSH IBS 5
SUB IBS 1 IBS 2 IBS 5
CVI IBS 5 IBS 4
PSH VDW 4 1 1
SET IBS 4 IBS 4
*)

Program Test;

Type
  Number = Integer;

Var
    b : Byte;
    i : Integer;

Begin
    b := Byte(i);
    i := Integer(b);
    i := Integer(b) + 200;
    i := Number(b);
    i := Integer(200 - 5);
End.
