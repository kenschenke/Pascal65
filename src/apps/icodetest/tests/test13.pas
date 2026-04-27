(* Test 13 - Routines
NEW IWS 10
DIA ILS 0
NEW IWS 4
DIR ILS 0
PSH FLT 
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 7b
PSH VDW 4 2 0
SET IBS 4 IBS 2
PSH CHR k
PSH VDW 9 2 2
SET IBS 9 IBS 9
PSH FLT 123.456
PSH VVW 7 2 1
SET IBS 7 IBS 7
RTS
LOC LBL xxxxx
RTS
LOC LBL xxxxx
PSH IWU 3039
PSH VVR b 2 0
MEM IBS b
PSH IBS 3
AIX IBS 2
SET IBS 4 IBS 4
RTS
LOC LBL xxxxx
PSH IWU 3039
PSH VDR 14 2 0
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 4
RTS
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH IWU 3039
PSH VDW 7 1 2
PSH CHR x
ASF IBS 2
JSR LBL xxxxx IBS 0 IBS 0
LOC LBL xxxxx
POP
POP
POP
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH IWU 10e1
ASF IBS 2
JSR LBL xxxxx IBS 0 IBS 0
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 7 1 2
SET IBS 7 IBS 7
PUF IBS 2 LBL xxxxx
PSH VDW b 1 0
ASF IBS 2
JSR LBL xxxxx IBS 0 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH VDR 14 1 1
DCC LBL xxxxx IBS 2
ASF IBS 2
JSR LBL xxxxx IBS 0 IBS 0
LOC LBL xxxxx
DCF LBL xxxxx IBS 2
POF IBS 0 IBS 0
*)

Program Test;

Type
  MyArray = Array[1..5] Of Integer;
  MyRec = Record
    a, b : Integer;
  End;

Var
  arr : MyArray;
  rec : MyRec;
  fr : Real;

Procedure MyProc(i : Integer; Var r : Real; ch : Char);
Begin
  i := 123;
  ch := 'k';
  r := 123.456;
End;

Function MyFunc(i : Integer) : Real;
Begin
End;

Procedure ArrayProc(Var a : MyArray);
Begin
  a[3] := 12345;
End;

Procedure RecProc(r : MyRec);
Begin
  r.b := 12345;
End;

Begin
  MyProc(12345, fr, 'x');
  fr := MyFunc(4321);
  ArrayProc(arr);
  RecProc(rec);
End.
