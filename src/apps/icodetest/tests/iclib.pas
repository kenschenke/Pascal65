// A library unit for icode test 35. It has no code of its own.

Unit IcLib;

Interface

Type
  Callback = Procedure;

Var
  LibCount : Integer;
  LibCb : Callback;

Procedure LibProc(n : Integer);

Implementation Library

End.
