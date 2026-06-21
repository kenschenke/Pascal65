(* Test 14 - Files
PSH ILS 0
PSH ILS 0
BRA LBL xxxxx
LOC LBL xxxxx
RTS
LOC LBL xxxxx
RTS
LOC LBL xxxxx
PUF IBS 2 LBL xxxxx
PSH VDW 18 1 0
ASF IBS 2
JSR LBL xxxxx IBS 0 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
PUF IBS 2 LBL xxxxx
PSH VDW 17 1 1
ASF IBS 2
JSR LBL xxxxx IBS 0 IBS 0
LOC LBL xxxxx
POP
POF IBS 0 IBS 0
*)

Program Test;

Var
  ft : Text;
  fh : File Of Integer;

Procedure TextProc(Var f : Text);
Begin
End;

Procedure FileProc(Var f : File);
Begin
End;

Begin
  TextProc(ft);
  FileProc(fh);
End.
