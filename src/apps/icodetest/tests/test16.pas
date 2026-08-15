(* Test 16 - Read, Readln, Readstr
PSH IWU 0
PSH CHR 
NEW IWS 10
DIA LBL xxxxx
SST ILS 0
PSH ILS 0
BRA LBL xxxxx
LOC LBL xxxxx
SFH IBS 80 IBS 1
PSH VDW 4 1 0
INP IBS 4
SFH IBS 0 IBS 1
SFH IBS 80 IBS 1
PSH VDW 4 1 0
INP IBS 4
PSH VDW 9 1 1
INP IBS 9
CNL
SFH IBS 0 IBS 1
SFH IBS 80 IBS 1
PSH VDW b 1 2
INP IBS b
CNL
SFH IBS 0 IBS 1
SFH IBS 80 IBS 1
PSH VDW 15 1 3
INP IBS 15
CNL
SFH IBS 0 IBS 1
PSH VDR 17 1 4
SFH IBS 82 IBS 1
PSH VDW 4 1 0
PSH IWS 2
INP IBS 19
SFH IBS 0 IBS 1
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

Begin
  Read(i);
  Readln(i, ch);
  Readln(arr);
  Readln(str);
  Read(fh, i);
End.
