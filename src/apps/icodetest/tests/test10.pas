(* Test 10 - Records
NEW IWS e
DIR ILS 0
NEW IWS 16
DIR ILS 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH IWU 3039
PSH VVR 14 1 0
SET IBS 4 IBS 4
PSH FLT 3.14
PSH VVR 14 1 0
PSH IBS 4
ADD IBS 3 IBS 3 IBS 3
SET IBS 7 IBS 7
PSH IWU 5ba0
PSH VVR 14 1 0
PSH IBS 8
ADD IBS 3 IBS 3 IBS 3
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 4
PSH IBS 7b
PSH VVR 14 1 0
PSH IBS c
ADD IBS 3 IBS 3 IBS 3
PSH IBS 1
ADD IBS 3 IBS 3 IBS 3
SET IBS 1 IBS 2
PSH IWU 10e1
PSH VVR 14 1 1
SET IBS 4 IBS 4
PSH STR Hello, World
PSH VVR 14 1 1
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 15 IBS a
PSH IWU 7d84
PSH VVR 14 1 1
PSH IBS 4
ADD IBS 3 IBS 3 IBS 3
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 4
PSH IWU 5b8a
PSH VVR 14 1 1
PSH IBS 12
ADD IBS 3 IBS 3 IBS 3
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 4
*)

Program Test;

Type
  MySubRec = Record
    a, b : Byte;
  End;
  MyRec = Record
    i, j : Integer;
    r : Real;
    SubRec : Record
      x, y : Integer;
    End;
    my : MySubRec;
  End;

Var
  rec : MyRec;
  otherRec : Record
    a : Integer;
    s : String;
    rec : MyRec;
    AlsoRec : Record
      m, n : Integer;
    End;
  End;

Begin
  rec.i := 12345;
  rec.r := 3.14;
  rec.subrec.y := 23456;
  rec.my.b := 123;
  otherRec.a := 4321;
  otherRec.s := 'Hello, World';
  otherRec.rec.j := 32132;
  otherRec.AlsoRec.n := 23434;
End.
