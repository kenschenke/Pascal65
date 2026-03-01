(* Test 16 - Read, Readln, Readstr
PSH IWU 0
PSH CHR 
NEW IWS 10
DIA ILS 0
SST ILS 0
PSH ILS 0
BRA LBL xxxxx
LOC LBL xxxxx
SFH IBS 80 IBS 1
PSH VVW 4 1 0
INP IBS 4
SFH IBS 0 IBS 1
SFH IBS 80 IBS 1
PSH VVW 4 1 0
INP IBS 4
PSH VVW 9 1 1
INP IBS 9
CNL
SFH IBS 0 IBS 1
SFH IBS 80 IBS 1
PSH VVW b 1 2
INP IBS b
CNL
SFH IBS 0 IBS 1
SFH IBS 80 IBS 1
PSH VVW 15 1 3
INP IBS 15
CNL
SFH IBS 0 IBS 1
SFH IBS 82 IBS 1
PSH VVW 4 1 0
PSH IWS 2
INP IBS 19
SFH IBS 0 IBS 1
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
