(* Test 11 - Pointers
PSH IWU 0
NEW IWS 10
DIA LBL xxxxx
PSH IWU 0
PSH IWU 0
NEW IWS 8
DIR LBL xxxxx
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
PSH VDW 4 1 0
PSH VDW 1b 1 2
SET IBS 1b IBS 1c
PSH IWU 3039
PSH VDR 1b 1 2
SET IBS 4 IBS 4
PSH VDR 14 1 4
PSH VDW 1b 1 3
SET IBS 1b IBS 1c
PSH IBS 7b
PSH VDR 1b 1 3
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 2
PSH VDR b 1 1
PSH IBS 2
AIX IBS 2
PSH VDW 1b 1 2
SET IBS 1b IBS 1c
PSH VDW b 1 1
PSH VDW 1b 1 5
SET IBS 1b IBS 1c
PSH IBS ea
PSH VDR 1b 1 5
MEM IBS b
PSH IBS 5
AIX IBS 2
SET IBS 4 IBS 1
PSH VDR 1b 1 5
MEM IBS b
PSH IBS 2
AIX IBS 2
MEM IBS 4
PSH VDW 4 1 0
SET IBS 4 IBS 4
PRP LBL xxxxx IBS 2 IBS 0
PSH VDW 1e 1 7
SET IBS 1e IBS 1d
PSH VDR 1e 1 7
PPF LBL xxxxx
PSH IWU 1c8
PSH VDR 1e 1 7
JRP
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PRP LBL xxxxx IBS 2 IBS 0
PSH VDW 1e 1 8
SET IBS 1e IBS 1d
PSH VDR 1e 1 8
PPF LBL xxxxx
PSH BOO 1
PSH VDR 1e 1 8
JRP
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 9 1 6
SET IBS 9 IBS 9
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 5
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 2 LBL xxxxx
   heap offset: 0
   rec size: 8
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
