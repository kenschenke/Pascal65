// A unit for wdsearch.pas, on the work disk. The system disk has
// wdunitsys.pas as wdunit.pas, which must not be found.

Unit WdUnit;

Interface

Var
    wdName : String = 'work';

Function WdWhere : Integer;

Implementation

Function WdWhere : Integer;
Begin
    WdWhere := 9;
End;

End.
