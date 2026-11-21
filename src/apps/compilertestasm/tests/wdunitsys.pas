// The system disk's wdunit.pas, for wdsearch.pas. The work disk's
// wdunit.pas is found first, so this one must never be compiled.

Unit WdUnit;

Interface

Var
    wdName : String = 'system';

Function WdWhere : Integer;
Procedure WdSystemOnly;

Implementation

Function WdWhere : Integer;
Begin
    WdWhere := 8;
End;

Procedure WdSystemOnly;
Begin
End;

End.
