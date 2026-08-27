(* Test 10 - Records
NEW IWS c
DIR LBL xxxxx
NEW IWS 14
DIR LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
DAT IBU 2 LBL xxxxx
   heap offset: 8
   rec size: 4
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 12
   fields:
      offset: 8, RECORD, xxxxx
DAT IBU 2 LBL xxxxx
   heap offset: 12
   rec size: 4
DAT IBU 2 LBL xxxxx
   heap offset: 4
   rec size: 12
   fields:
      offset: 8, RECORD, xxxxx
DAT IBU 2 LBL xxxxx
   heap offset: 32
   rec size: 4
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 20
   fields:
      offset: 2, STRING
      offset: 4, RECORD, xxxxx
      offset: 16, RECORD, xxxxx
*)

Program Test;

Type
  MyRec = Record
    i, j : Integer;
    r : Real;
    SubRec : Record
      x, y : Integer;
    End;
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
  // rec.i := 12345;
  // rec.r := 3.14;
  // rec.subrec.y := 23456;
  // rec.my.b := 123;
  // otherRec.a := 4321;
  // otherRec.s := 'Hello, World';
  // otherRec.rec.j := 32132;
  // otherRec.AlsoRec.n := 23434;
End.
