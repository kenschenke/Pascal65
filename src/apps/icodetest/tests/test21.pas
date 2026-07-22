(* Test 21 - Enumerations
NEW IWS 14
DIA LBL xxxxx
PSH IWU 0
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 12 2 0
SUC IBS 3
PSH RET 
SET IBS 12 IBS 12
RTS
LOC LBL xxxxx
PSH VDR 12 2 0
SUC IBS 3
PSH VDW 12 2 0
SET IBS 12 IBS 12
RTS
LOC LBL xxxxx
PSH IWU 0
PSH VDW 12 1 1
SET IBS 12 IBS 13
PSH IWU 6
PSH VDW 12 1 1
SET IBS 12 IBS 13
PUF IBS 2 LBL xxxxx
PSH VDR 12 1 1
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 12 1 1
SET IBS 12 IBS 12
PUF IBS 2 LBL xxxxx
PSH IWU 0
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 12 1 1
SET IBS 12 IBS 12
PUF IBS 2 LBL xxxxx
PSH IWU 2
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 12 1 1
SET IBS 12 IBS 12
PUF IBS 2 LBL xxxxx
PSH VDR 12 1 1
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH IWU 0
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH IWU 3
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 12 1 1
PSH VDW 4 1 2
SET IBS 4 IBS 4
PSH IWU 0
PSH VDW 4 1 2
SET IBS 4 IBS 4
PSH IWU 4
PSH VDW 4 1 2
SET IBS 4 IBS 4
PSH VDR 12 1 1
PRE IBS 3
PSH VDW 12 1 1
SET IBS 12 IBS 12
PSH IWU 5
PRE IBS 3
PSH VDW 12 1 1
SET IBS 12 IBS 12
PSH IWU 0
SUC IBS 3
PSH VDW 12 1 1
SET IBS 12 IBS 12
PSH IBS 64
PSH VDR b 1 0
PSH IWU 0
AIX IBS 13
SET IBS 4 IBS 2
PSH IBS c8
PSH VDR b 1 0
PSH IWU 1
AIX IBS 13
SET IBS 4 IBS 1
PSH IWU 12c
PSH VDR b 1 0
PSH IWU 2
AIX IBS 13
SET IBS 4 IBS 4
PSH IWU 190
PSH VDR b 1 0
PSH VDR 12 1 1
AIX IBS 12
SET IBS 4 IBS 4
LOC LBL xxxxx
PSH VDR 12 1 1
PSH IWU 0
EQU IBS 12 IBS 13
BIT LBL xxxxx
PSH VDR 12 1 1
PSH IWU 3
EQU IBS 12 IBS 13
BIT LBL xxxxx
PSH VDR 12 1 1
PSH IWU 4
EQU IBS 12 IBS 13
BIT LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS 5
PSH VDW 4 1 2
SET IBS 4 IBS 2
BRA LBL xxxxx
LOC LBL xxxxx
PSH VDR 12 1 1
PSH IWU 2
EQU IBS 12 IBS 13
BIT LBL xxxxx
PSH VDR 12 1 1
PSH IWU 5
EQU IBS 12 IBS 13
BIT LBL xxxxx
BRA LBL xxxxx
LOC LBL xxxxx
PSH IBS a
PSH VDW 4 1 2
SET IBS 4 IBS 2
LOC LBL xxxxx
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: 6
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
*)

Program Test;

Type
   Colors = (Red, Orange, Yellow, Green, Blue, Indigo, Violet);
   MyArray = Array[Red..Violet] Of Integer;

Var
   arr : MyArray;
   color : Colors;
   i : Integer;

Function ColorFunc(c : Colors) : Colors;
Begin
   ColorFunc := Succ(c);
End;

Procedure ColorProc(c : Colors);
Begin
   c := Succ(c);
End;

Begin
   color := Red;
   color := Violet;

   color := ColorFunc(color);
   color := ColorFunc(Red);
   color := ColorFunc(Yellow);
   ColorProc(color);
   ColorProc(Red);
   ColorProc(Green);
   i := Ord(color);
   i := Ord(Red);
   i := Ord(Blue);
   color := Pred(color);
   color := Pred(Indigo);
   color := Succ(Red);

   arr[Red] := 100;
   arr[Orange] := 200;
   arr[Yellow] := 300;
   arr[color] := 400;

   Case color Of
      Red, Green, Blue: i := 5;
      Yellow, Indigo: i := 10;
   End;
End.
