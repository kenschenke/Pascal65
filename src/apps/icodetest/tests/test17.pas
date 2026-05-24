(* Test 17 - Write, Writeln, Writestr
PSH IWU 0
PSH CHR 
NEW IWS 10
DIA LBL xxxxx
SST ILS 0
PSH ILS 0
PSH FLT 
BRA LBL xxxxx
LOC LBL xxxxx
SFH IBS 80 IBS 0
PSH VDR 4 1 0
PSH IBS 0
PSH IBS ff
OUT IBS 4
SFH IBS 0 IBS 0
SFH IBS 80 IBS 0
PSH VDR 4 1 0
PSH IBS 0
PSH IBS ff
OUT IBS 4
PSH VDR 9 1 1
PSH IBS 0
PSH IBS ff
OUT IBS 9
ONL
SFH IBS 0 IBS 0
SFH IBS 80 IBS 0
PSH VDR b 1 2
PSH IBS 0
PSH IBS ff
OUT IBS b
ONL
SFH IBS 0 IBS 0
SFH IBS 80 IBS 0
PSH VDR 15 1 3
PSH IBS 0
PSH IBS ff
OUT IBS 15
ONL
SFH IBS 0 IBS 0
SFH IBS 80 IBS 0
PSH STR Hello, World
PSH IBS 0
PSH IBS ff
OUT IBS a
ONL
SFH IBS 0 IBS 0
SFH IBS 80 IBS 0
PSH CHR x
PSH IBS 0
PSH IBS ff
OUT IBS 9
ONL
SFH IBS 0 IBS 0
PSH VDR 17 1 4
SFH IBS 82 IBS 0
PSH IWS 2
OUT IBS 19
SFH IBS 0 IBS 0
SFH IBS 80 IBS 0
PSH VDR 7 1 5
PSH IBS 6
PSH IBS 2
OUT IBS 7
ONL
SFH IBS 0 IBS 0
SFH IBS 81 IBS 0
PSH VDR 4 1 0
PSH IBS 0
PSH IBS ff
OUT IBS 4
PSH VDR 9 1 1
PSH IBS 0
PSH IBS ff
OUT IBS 9
FSO
SFH IBS 0 IBS 0
PSH VDW 15 1 3
SET IBS 15 IBS 16
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 10
   elem size: 1
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
*)

Program Test;

Var
  i : Integer;
  ch : Char;
  arr : Array[1..10] Of Char;
  str : String;
  fh : File Of Integer;
  r : Real;

Begin
  Write(i);
  Writeln(i, ch);
  Writeln(arr);
  Writeln(str);
  Writeln('Hello, World');
  Writeln('x');
  Write(fh, i);
  Writeln(r:6:2);
  str := WriteStr(i, ch);
End.
