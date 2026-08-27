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
  i := 1234;
  p := true;
End;

Function PublicFunc(a : Boolean ) : Real;
Var
  s : String;
Begin
  a := False;
  s := 'Hello, World';
End;

Procedure PrivateProc(b : Word);
Var
  c, d : Cardinal;
Begin
  b := 1234;
  c := 123456;
  d := 234567;
End;

End.
