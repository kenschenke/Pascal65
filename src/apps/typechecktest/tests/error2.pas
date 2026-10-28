// Error Test 2 - Assignment Errors and Warnings (Part 2)

Program TestCast;

Var
    b : Byte;
    pb : ^Byte;
    s : ShortInt;
    ps : ^ShortInt;
    w : Word;
    pw : ^Word;
    i : Integer;
    pi : ^Integer;
    c : Cardinal;
    pc : ^Cardinal;
    l : LongInt;
    pl : ^LongInt;
    r : Real;

Begin
    // Byte Tests
    pb^ := -123;    (* $ExpectWarn 66 *)
    pb^ := 12345;   (* $ExpectWarn 66 *)
    pb^ := -12345;  (* $ExpectWarn 66 *)
    pb^ := 123456;  (* $ExpectWarn 66 *)
    pb^ := -123456; (* $ExpectWarn 66 *)
    pb^ := 200;
    pb^ := s;       (* $ExpectWarn 66 *)
    pb^ := w;       (* $ExpectWarn 66 *)
    pb^ := i;       (* $ExpectWarn 66 *)
    pb^ := c;       (* $ExpectWarn 66 *)
    pb^ := l;       (* $ExpectWarn 66 *)
    pb^ := r;       (* $ExpectError 38 *)
    pb^ := 123.45;  (* $ExpectError 38 *)

    // ShortInt Tests
    ps^ := 200;     (* $ExpectWarn 66 *)
    ps^ := 12345;   (* $ExpectWarn 66 *)
    ps^ := -12345;  (* $ExpectWarn 66 *)
    ps^ := 123456;  (* $ExpectWarn 66 *)
    ps^ := -123456; (* $ExpectWarn 66 *)
    ps^ := 123;
    ps^ := b;       (* $ExpectWarn 66 *)
    ps^ := w;       (* $ExpectWarn 66 *)
    ps^ := i;       (* $ExpectWarn 66 *)
    ps^ := c;       (* $ExpectWarn 66 *)
    ps^ := l;       (* $ExpectWarn 66 *)
    ps^ := r;       (* $ExpectError 38 *)
    ps^ := -123.45; (* $ExpectError 38 *)

    // Word Tests
    pw^ := -123;    (* $ExpectWarn 66 *)
    pw^ := -12345;  (* $ExpectWarn 66 *)
    pw^ := 123456;  (* $ExpectWarn 66 *)
    pw^ := -123456; (* $ExpectWarn 66 *)
    pw^ := 40000;
    pw^ := b;
    pw^ := s;       (* $ExpectWarn 66 *)
    pw^ := i;       (* $ExpectWarn 66 *)
    pw^ := c;       (* $ExpectWarn 66 *)
    pw^ := l;       (* $ExpectWarn 66 *)
    pw^ := r;       (* $ExpectError 38 *)
    pw^ := 1234.56; (* $ExpectError 38 *)

    // Integer Tests
    pi^ := 40000;   (* $ExpectWarn 66 *)
    pi^ := 123456;  (* $ExpectWarn 66 *)
    pi^ := -123456; (* $ExpectWarn 66 *)
    pi^ := -12345;
    pi^ := b;
    pi^ := s;
    pi^ := w;       (* $ExpectWarn 66 *)
    pi^ := c;       (* $ExpectWarn 66 *)
    pi^ := l;       (* $ExpectWarn 66 *)
    pi^ := r;       (* $ExpectError 38 *)
    pi^ := 1234.56; (* $ExpectError 38 *)

    // Cardinal Tests
    pc^ := -123;    (* $ExpectWarn 66 *)
    pc^ := -12345;  (* $ExpectWarn 66 *)
    pc^ := -123456; (* $ExpectWarn 66 *)
    pc^ := 123456;
    pc^ := b;
    pc^ := s;       (* $ExpectWarn 66 *)
    pc^ := w;
    pc^ := i;       (* $ExpectWarn 66 *)
    pc^ := l;       (* $ExpectWarn 66 *)
    pc^ := r;       (* $ExpectError 38 *)
    pc^ := 1234.56; (* $ExpectError 38 *)

    // LongInt Tests
    pl^ := 2247483647;  (* $ExpectWarn 66 *)
    pl^ := -123456;
    pl^ := s;
    pl^ := b;
    pl^ := w;
    pl^ := i;
    pl^ := c;       (* $ExpectWarn 66 *)
    pl^ := r;       (* $ExpectError 38 *)
    pl^ := 1234.56; (* $ExpectError 38 *)
End.
