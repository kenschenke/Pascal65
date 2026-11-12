// Error Test 12 - Unary minus of non-literals
//
// A signed integer or a real keeps its type. Byte becomes Integer, and
// Word and Cardinal become LongInt. The loss of precision warnings show
// the type each negation gets. Negating any other type is an error, and
// assigning the result is another.

Program NegTypes;

Type
    Small = 1..10;

Var
    b : Byte;
    s : ShortInt;
    w : Word;
    i : Integer;
    c : Cardinal;
    l : LongInt;
    r : Real;
    sm : Small;
    bool : Boolean;
    ch : Char;
    str : String;
    a : Array[1..3] Of Integer;

Function F : Byte;
Begin
    F := 1;
End;

Begin
    s := -s;
    s := -b;        (* $ExpectWarn 66 *)
    i := -b;
    i := -s;
    i := -i;
    i := -w;        (* $ExpectWarn 66 *)
    l := -w;
    l := -c;
    l := -l;
    b := -b;        (* $ExpectWarn 66 *)
    r := -r;
    r := -i;
    i := -sm;
    i := -F;
    i := -F();
    i := -a[2];
    i := -(i + 1);
    i := -Integer(w);
    i := -i * -i;
    s := -(s);
    bool := -bool;  (* $ExpectError 35 *) (* $ExpectError 38 *)
    ch := -ch;      (* $ExpectError 35 *) (* $ExpectError 38 *)
    str := -str;    (* $ExpectError 35 *) (* $ExpectError 38 *)
End.
