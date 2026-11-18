// A unit for icode test 39. Its variables need the heap, so its init
// block allocates and initializes them.

Unit IcUnit2;

Interface

Type
  Pair = Record
    a, b : Integer;
  End;

Var
  Name : String = 'hi';
  Nums : Array[1..2] Of Integer = (5, 6);

Procedure SetPair;

Implementation

Var
  P : Pair;

Procedure SetPair;
Begin
  P.a := 1;
End;

End.
