// Error Test 9 - Forward declarations that don't match

Program TestForward;

Type
    TStat = Array[1..5] Of Integer;
    TOther = Array[1..6] Of Integer;
    Colors = (Red, Green, Blue);
    Shades = (Light, Dark);
    TRec1 = Record a : Integer; End;
    TRec2 = Record a : Integer; End;

Var
    i : Integer;

Procedure Same(a : Integer; b : Char); Forward;
Function SameFunc(a : Integer) : Integer; Forward;
Procedure NoParams; Forward;
Procedure MoreParams(a : Integer); Forward;
Procedure FewerParams(a, b : Integer); Forward;
Procedure OtherType(a : Integer); Forward;
Procedure OtherArray(a : TStat); Forward;
Function RetStr : String; Forward;
Function RetColor : Colors; Forward;
Function RetRec : TRec1; Forward;
Function RetReal : Integer; Forward;
Function RetEnum : Colors; Forward;
Function RetOtherRec : TRec1; Forward;
Function RetChar(a : Integer) : Char; Forward;

Procedure Same(a : Integer; b : Char); Begin i := 1; End;
Function SameFunc(a : Integer) : Integer; Begin SameFunc := a; End;
Procedure NoParams; Begin i := 1; End;
Procedure MoreParams(a, b : Integer); Begin i := 1; (* $ExpectError 50 *) End;
Procedure FewerParams(a : Integer); Begin i := 1; (* $ExpectError 50 *) End;
Procedure OtherType(a : Char); Begin i := 1; (* $ExpectError 35 *) End;
Procedure OtherArray(a : TOther); Begin i := 1; (* $ExpectError 35 *) End;

// Return types
Function RetStr : String; Begin RetStr := 'a'; End;
Function RetColor : Colors; Begin RetColor := Red; End;
Function RetRec : TRec1; Begin i := 1; End;
Function RetReal : Real; Begin i := 1; (* $ExpectError 35 *) End;
Function RetEnum : Shades; Begin i := 1; (* $ExpectError 35 *) End;
Function RetOtherRec : TRec2; Begin i := 1; (* $ExpectError 35 *) End;
Function RetChar(a : Integer) : Byte; Begin i := 1; (* $ExpectError 35 *) End;

// A routine without a forward declaration
Procedure NoForward(a : Integer); Begin i := 1; End;

Begin
    i := 0;
End.
