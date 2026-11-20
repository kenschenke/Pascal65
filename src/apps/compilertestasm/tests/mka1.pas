// Make tests (compiletests.s): the harness copies mka1.pas, mka2.pas
// (only its implementation changed) and mka3.pas (its interface changed)
// to mka.pas. Their interfaces start on the same line.

Unit MkA;

Interface

Function MkAVal : Integer;

Implementation

Function MkAVal : Integer;
Begin
    MkAVal := 1;
End;

End.
