// A library unit for icode tests 35 and 39. It has no code of its own.

Unit IcLib;

Interface

Type
  Callback = Procedure;
  LibRec = Record
    a, b : Integer;
  End;

Var
  LibCount : Integer;
  LibCb : Callback;
  LibPt : LibRec;

Procedure LibProc(n : Integer);

Implementation Library

End.
