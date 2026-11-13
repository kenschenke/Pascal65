(* Test 34 - System library calls
PSH FLT 
SST ILS 0
PSH IBS 0
PSH IWU 0
PSH ILS 0
PSH CHR 
PSH IBS 0
PSH BOO 0
BRA LBL xxxxx
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH VDR 7 1 0
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 7 1 0
SET IBS 7 IBS 7
PUF IBS 2 LBL xxxxx
PSH VDR 15 1 1
SCV IBS 15
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
DEL
POF IBS 1 IBS 0
PSH VDW 15 1 1
SET IBS 15 IBS 15
PUF IBS 2 LBL xxxxx
PSH VDR 3 1 3
CVI IBS 3 IBS 5
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 1 1 2
SET IBS 1 IBS 1
PUF IBS 2 LBL xxxxx
PSH VDR 5 1 4
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 1 1 2
SET IBS 1 IBS 1
PUF IBS 2 LBL xxxxx
PSH VDR 5 1 4
PSH VDR 1 1 2
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POP
POP
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH VDR 2 1 6
CVI IBS 2 IBS 6
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POP
POF IBS 1 IBS 0
PSH VDW 8 1 7
SET IBS 8 IBS 8
PUF IBS 2 LBL xxxxx
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 1
LOC LBL xxxxx
POF IBS 1 IBS 0
PSH VDW 9 1 5
SET IBS 9 IBS 9
*)

// A call to a library routine. The routine reads its arguments as its
// parameters' types, so an integer argument smaller than its parameter
// is converted (CVI), which sign-extends a negative one. A string passed
// by value is copied and freed after the call. Sin needs the runtime's
// trig package.

Program Test;

Var
  r : Real;
  s : String;
  b : Byte;
  w : Word;
  c : Cardinal;
  ch : Char;
  sh : ShortInt;
  bo : Boolean;

Begin
  r := Sin(r);
  s := UpCase(s);
  b := Peek(w);
  b := Peek(c);
  Poke(c, b);
  bo := Odd(sh);
  ch := GetKey;
End.
