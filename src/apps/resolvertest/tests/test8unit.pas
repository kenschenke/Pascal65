(* Test 8 - Unit *)

Unit Test8Unit;

Interface

Var
  PublicVar : String;

Procedure PublicProc(i : Integer);
Function PublicFunc(a : Boolean) : Real;

Implementation

Var
  PrivateVar : Integer;

Procedure PublicProc(i : Integer);
Var
  p : Boolean;
Begin
  Writeln('In Public Proc', i);
End;

Function PublicFunc(a : Boolean ) : Real;
Var
  s : String;
Begin
  Writeln('In Public Func', s);
End;

Procedure PrivateProc(b : Word);
Var
  c, d : Cardinal;
Begin
  Writeln('In Private Proc', c);
End;

End.
