(* Test 37 - Dereferenced Var arguments and pointer offsets
PSH IWU 0
PSH IBS 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH VVR 4 2 0
MEM IBS 4
PSH IBS 1
ADD IBS 4 IBS 2 IBS 4
PSH VVW 4 2 0
SET IBS 4 IBS 4
RTS
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH VDR 1b 1 0
ASF IBS 2
JSR LBL xxxxx IBS 2 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PSH VDR 1b 1 0
MEM IBS 4
PSH IBS 1
ADD IBS 4 IBS 1 IBS 4
PSH VDR 1b 1 0
SET IBS 4 IBS 4
PSH VDR 1b 1 0
PSH IBS 64
PSH IWS 2
MUL IBS 2 IBS 4 IBS 4
ADD IBS 1b IBS 4 IBS 1c
PSH VDW 1b 1 0
SET IBS 1b IBS 1c
PSH VDR 1b 1 0
PSH VDR 1 1 1
PSH IWS 2
MUL IBS 1 IBS 4 IBS 4
SUB IBS 1b IBS 4 IBS 1c
PSH VDW 1b 1 0
SET IBS 1b IBS 1c
PSH VDR 1b 1 0
PSH IBS 64
PSH IWS 2
MUL IBS 2 IBS 4 IBS 4
SUB IBS 1b IBS 4 IBS 1b
PSH VDW 1b 1 0
SET IBS 1b IBS 1b
*)

// The address of p^ is the value of p, so p^ passed to a Var parameter
// or to Inc is p's value, with no MEM. An offset added to a pointer is
// multiplied by the size of what it points to as an Integer: 100 is a
// ShortInt, but 200 bytes is not.

Program Test;

Var
  ip : ^Integer;
  b : Byte;

Procedure Bump(Var n : Integer);
Begin
  n := n + 1;
End;

Begin
  Bump(ip^);
  Inc(ip^);
  ip := ip + 100;
  ip := ip - b;
  Dec(ip, 100);
End.
