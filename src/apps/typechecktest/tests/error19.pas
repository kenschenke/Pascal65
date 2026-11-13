// Error Test 19 - Declarations, initial values, casts and forwards
//
// Array index types, arrays of arrays, initial values, nested array
// literals, type casts and forward declarations with enumeration and
// array parameters that don't match: the elements, an index of another
// kind or enumeration, and the limits.
//
// The parser only takes an $Expect directive in a statement, so a
// declaration with an error is in a routine on one line, with the
// directive in the routine's statements.

Program Decls;

Type
    Color = (Red, Green, Blue);
    Shade = (Light, Dark);
    TMy = Byte;
    TCh = Char;
    TBo = Boolean;
    TRe = Real;
    TGrid = Array[1..2] Of Array[1..2] Of Byte;
    TByColor = Array[Color] Of Byte;
    TSh = Array[Shade] Of Byte;
    TStat = Array[1..3] Of Byte;
    TWords = Array[1..3] Of Word;
    TWide = Array[1..300] Of Byte;
    TChars = Array['a'..'c'] Of Byte;
    TDyn = Array Of Integer;

Var
    i : Integer;
    b : Byte;
    ch : Char;
    col : Color;
    bool : Boolean;
    r : Real;
    grid : TGrid = ((1, 2), (3, 4));

Procedure Nested; Var g : TGrid = ((1, 2), 3); Begin (* $ExpectError 23 *) End;
Procedure Many; Var a : TStat = (1, 2, 3, 4); Begin (* $ExpectError 62 *) End;
Procedure NotLiteral; Var a : TStat = 5; Begin (* $ExpectError 23 *) End;
Procedure NotConst; Var j : Integer = i; Begin (* $ExpectError 23 *) End;

Procedure EnumFwd(c : Color); Forward;
Procedure ElemFwd(a : TStat); Forward;
Procedure Idx(a : TStat); Forward;
Procedure EIdx(a : TByColor); Forward;
Procedure SameIdx(a : TByColor; d : TDyn); Forward;

Procedure EnumFwd(c : Shade); Begin i := 1; (* $ExpectError 35 *) End;
Procedure ElemFwd(a : TWords); Begin i := 1; (* $ExpectError 35 *) End;
Procedure Idx(a:TWide); Begin (* $ExpectError 35 *) (* $ExpectError 35 *) End;
Procedure EIdx(a:TSh); Begin (* $ExpectError 35 *) (* $ExpectError 35 *) End;
Procedure SameIdx(a : TByColor; d : TDyn); Begin i := 1; End;

Begin
    // Type casts
    ch := TCh(65);
    bool := TBo(1);
    i := Integer(Red);
    col := Color(1);
    b := TMy(i);
    b := TMy(1, 2);     (* $ExpectError 50 *) (* $ExpectError 38 *)
    r := TRe(5);        (* $ExpectError 65 *) (* $ExpectError 38 *)
    i := Integer(r);                    (* $ExpectError 65 *)
    b := TMy(r);        (* $ExpectError 65 *) (* $ExpectError 38 *)
    b := TMy();         (* $ExpectError 50 *) (* $ExpectError 38 *)
End.
