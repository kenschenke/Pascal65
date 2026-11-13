// Error Test 16 - Expressions
//
// Pointer arithmetic, shifts, Not, comparisons, assignment targets,
// subscripts and the types of binary expressions and literals.

Program Exprs;

Type
    Color = (Red, Green, Blue);
    Shade = (Light, Dark);
    TRec = Record a : Integer; End;
    TRecA = Record arr : Array[1..3] Of Byte; End;
    PInt = ^Integer;

Const
    Big = 1000;

Var
    b : Byte;
    sh : ShortInt;
    w : Word;
    i : Integer;
    c : Cardinal;
    l : LongInt;
    r : Real;
    ch : Char;
    col : Color;
    bool : Boolean;
    str : String;
    p, q : PInt;
    pb : ^Byte;
    rec : TRec;
    ra : TRecA;
    ca : Array[Color] Of Integer;
    la : Array['a'..'z'] Of Byte;
    ia : Array[1..10] Of Byte;

Begin
    // Pointer arithmetic
    p := p + 1;
    p := p - 1;
    p := p + r;                     (* $ExpectError 35 *)
    p := p - ch;                    (* $ExpectError 35 *)
    p := p * 2;                     (* $ExpectError 35 *)

    // Shifts, Not and unary minus
    i := i << 2;
    i := i >> r;        (* $ExpectError 30 *) (* $ExpectError 38 *)
    bool := Not bool;
    i := Not i;
    bool := Not r;      (* $ExpectError 35 *) (* $ExpectError 38 *)
    i := -ch;           (* $ExpectError 35 *) (* $ExpectError 38 *)

    // Assignment targets
    TRec := 5;                      (* $ExpectError 37 *)
    Red := Green;                   (* $ExpectError 37 *)
    Big := 5;                       (* $ExpectError 38 *)
    col := Light;                   (* $ExpectError 38 *)
    i := TRec.a;        (* $ExpectError 37 *) (* $ExpectError 38 *)

    // Subscripts
    i := ca[Green];
    b := la['q'];
    ch := str[i];
    i := ca[Dark];                  (* $ExpectError 42 *)
    b := ia['x'];                   (* $ExpectError 42 *)
    b := ia[r];                     (* $ExpectError 42 *)
    ch := str['x'];     (* $ExpectError 42 *) (* $ExpectError 38 *)
    i := i[1];          (* $ExpectError 30 *) (* $ExpectError 38 *)

    // Comparisons
    bool := bool = bool;
    bool := ch < 'x';
    bool := col = Green;
    bool := col = 1;                (* $ExpectError 35 *)
    bool := col = Light;            (* $ExpectError 35 *)
    bool := p = q;
    bool := p = @i;
    bool := p = pb;                 (* $ExpectError 35 *)
    bool := p = i;                  (* $ExpectError 35 *)
    bool := i = p;                  (* $ExpectError 35 *)

    // Binary expression types: literals on the left, the widest of two
    // variables and literals bigger than the variable
    i := 2 * i;
    i := 1 + 2;
    l := l + b;
    sh := sh + b;
    i := i + w;
    l := l + c;
    w := b + 1000;
    c := b + 100000;
    i := sh + 1000;
    l := sh + 100000;
    c := w + 100000;
    l := i + 100000;
    w := 1000 + b;
    b := sh + b;                    (* $ExpectWarn 66 *)
    w := i + w;                     (* $ExpectWarn 66 *)

    // Negative literals that need a bigger type
    i := -200;
    l := -40000;
    sh := -200;                     (* $ExpectWarn 66 *)
    i := -40000;                    (* $ExpectWarn 66 *)

    // Constants that just fit and named constants
    sh := 127;
    i := 32767;
    w := Big;
    l := Big;

    // And and Or take Booleans
    bool := bool And i;             (* $ExpectError 35 *)

    // An element of an array field, and literals with 4-byte variables
    b := ra.arr[2];
    l := l + 5;
    c := c + 5;
End.
