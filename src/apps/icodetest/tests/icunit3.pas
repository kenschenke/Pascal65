// A unit for icode test 43. The program reaches each kind of entry from
// outside: a routine it calls and takes the address of, a record it
// passes by value and a dynamic array it sizes. Its routines' bodies are
// in a different order from the interface's, which numbers them.

Unit IcUnit3;

Interface

Type
  Pt = Record
    x, y : Integer;
  End;

Var
  Origin : Pt;
  Vals : Array Of Integer;

Procedure Show(p : Pt);
Procedure Bump(n : Integer);

Implementation

Var
  Count : Integer;

Procedure Bump(n : Integer);
Begin
  Count := Count + n;
End;

Procedure Show(p : Pt);
Begin
  Bump(p.y);
End;

End.
