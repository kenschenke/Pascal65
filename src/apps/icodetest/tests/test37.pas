(* Test 37 - Dereferenced Var arguments and pointer offsets
PSH IWU 0
PSH IBS 0
PSH IWU 0
PSH IWU 0
NEW IWS 12
DIA LBL xxxxx
PSH IWU 0
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
PSH VDR 1b 1 2
MEM IBS 1b
MEM IBS 4
PSH VDW 4 1 5
SET IBS 4 IBS 4
PSH VDR 4 1 5
PSH VDR 1b 1 2
MEM IBS 1b
SET IBS 4 IBS 4
PSH VDR 1b 1 3
MEM IBS 1b
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
PSH VDW 4 1 5
SET IBS 4 IBS 4
PSH VDR 4 1 5
PSH VDR 1b 1 3
MEM IBS 1b
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 4
PSH VDR b 1 4
PSH IBS 2
AIX IBS 2
MEM IBS 1b
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
MEM IBS 4
PSH VDW 4 1 5
SET IBS 4 IBS 4
PSH VDR 4 1 5
PSH VDR b 1 4
PSH IBS 2
AIX IBS 2
MEM IBS 1b
PSH IBS 2
ADD IBS 3 IBS 3 IBS 3
SET IBS 4 IBS 4
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 4
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
*)

// The address of p^ is the value of p, so p^ passed to a Var parameter
// or to Inc is p's value, with no MEM. An offset added to a pointer is
// multiplied by the size of what it points to as an Integer: 100 is a
// ShortInt, but 200 bytes is not. Reading p^^ reads twice (MEM), and a
// field of pp^^ or of ptrs[2]^ is at the pointer's value plus the field's
// offset.

Program Test;

Type
  Point = Record
    x, y : Integer;
  End;
  PointPtr = ^Point;
  IntPtr = ^Integer;

Var
  ip : IntPtr;
  b : Byte;
  ipp : ^IntPtr;
  pp : ^PointPtr;
  ptrs : Array[1..3] Of PointPtr;
  i : Integer;

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
  i := ipp^^;
  ipp^^ := i;
  i := pp^^.y;
  pp^^.y := i;
  i := ptrs[2]^.y;
  ptrs[2]^.y := i;
End.
