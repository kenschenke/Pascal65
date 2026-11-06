// Error Test 9 - Forward declarations that don't match

Program TestForward;

Type
    TStat = Array[1..5] Of Integer;
    TOther = Array[1..6] Of Integer;

Var
    i : Integer;

Procedure Same(a : Integer; b : Char); Forward;
Function SameFunc(a : Integer) : Integer; Forward;
Procedure NoParams; Forward;
Procedure MoreParams(a : Integer); Forward;
Procedure FewerParams(a, b : Integer); Forward;
Procedure OtherType(a : Integer); Forward;
Procedure OtherArray(a : TStat); Forward;

Procedure Same(a : Integer; b : Char); Begin i := 1; End;
Function SameFunc(a : Integer) : Integer; Begin SameFunc := a; End;
Procedure NoParams; Begin i := 1; End;
Procedure MoreParams(a, b : Integer); Begin i := 1; (* $ExpectError 50 *) End;
Procedure FewerParams(a : Integer); Begin i := 1; (* $ExpectError 50 *) End;
Procedure OtherType(a : Char); Begin i := 1; (* $ExpectError 35 *) End;
Procedure OtherArray(a : TOther); Begin i := 1; (* $ExpectError 35 *) End;

// A routine without a forward declaration
Procedure NoForward(a : Integer); Begin i := 1; End;

Begin
    i := 0;
End.
