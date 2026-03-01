(* Test 11 - Pointers
PSH IWU 0
NEW IWS 10
DIA ILS 0
PSH IWU 0
PSH IWU 0
NEW IWS 8
DIR ILS 0
PSH IWU 0
PSH CHR 
PSH ILS 0
PSH ILS 0
BRA LBL xxxxx
LOC LBL xxxxx
RTS
LOC LBL xxxxx
RTS
LOC LBL xxxxx
PSH VVW 4 1 0
PSH VVW 1b 1 2
SET IBS 1b IBS 1c
PSH IWU 3039
PSH VVR 1b 1 2
SET IBS 4 IBS 4
PSH VVW 14 1 4
PSH VVW 1b 1 3
SET IBS 1b IBS 1c
PSH IBS 7b
PSH VVR 1b 1 3
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 2
PSH VVR b 1 1
PSH IBS 2
AIX IBS 2
PSH VVW 1b 1 2
SET IBS 1b IBS 1c
PSH VVW b 1 1
PSH VVW 1b 1 5
SET IBS 1b IBS 1c
PSH IBS ea
PSH VVR 1b 1 5
MEM IBS b
PSH IBS 5
AIX IBS 2
SET IBS 4 IBS 1
PSH VVR 1b 1 5
MEM IBS b
PSH IBS 2
AIX IBS 2
MEM IBS 4
PSH VVW 4 1 0
SET IBS 4 IBS 4
PRP LBL xxxxx IBS 0 IBS 0
PSH VVW 1e 1 7
SET IBS 1e IBS 1d
PUF IBS 1 LBL xxxxx
PSH IWU 1c8
ASF IBS 1
JRP
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PRP LBL xxxxx IBS 0 IBS 0
PSH VVW 1e 1 8
SET IBS 1e IBS 1d
PUF IBS 1 LBL xxxxx
PSH BOO 1
ASF IBS 1
JRP
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VVW 9 1 6
SET IBS 9 IBS 9
*)

Program Test;

Type
  ProcType = Procedure(num : Integer);
  FuncType = Function(a : Boolean) : Char;
  MyRec = Record
    a, b : Integer;
    r : Real;
  End;
  ArrayType = Array[1..5] Of Integer;

Var
  i : Integer;
  arr : ArrayType;
  pi : ^Integer;
  pr : ^MyRec;
  rec : MyRec;
  pa : ^ArrayType;
  c : Char;
  pp : ProcType;
  pf : FuncType;

Procedure MyProc(abc : Integer);
Begin
End;

Function MyFunc(a : Boolean) : Char;
Begin
End;

Begin
  pi := @i;
  pi^ := 12345;
  pr := @rec;
  pr^.b := 123;
  pi := @arr[2];
  pa := @arr;
  pa^[5] := 234;
  i := pa^[2];
  pp := @MyProc;
  pp(456);
  pf := @MyFunc;
  c := pf(true);
End.
