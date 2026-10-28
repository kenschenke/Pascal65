// Error Test 1 - Assignment Errors and Warnings (Part 1)

Program TestCast;

Var
    b : Byte;
    s : ShortInt;
    w : Word;
    i : Integer;
    c : Cardinal;
    l : LongInt;
    r : Real;
    bool : Boolean;
    ch : Char;
    str : String;

Begin
    // Byte Tests
    b := -123;      (* $ExpectWarn 66 *)
    b := 12345;     (* $ExpectWarn 66 *)
    b := -12345;    (* $ExpectWarn 66 *)
    b := 123456;    (* $ExpectWarn 66 *)
    b := -123456;   (* $ExpectWarn 66 *)
    b := 200;
    b := s;         (* $ExpectWarn 66 *)
    b := w;         (* $ExpectWarn 66 *)
    b := i;         (* $ExpectWarn 66 *)
    b := c;         (* $ExpectWarn 66 *)
    b := l;         (* $ExpectWarn 66 *)
    b := r;         (* $ExpectError 38 *)
    b := 123.45;    (* $ExpectError 38 *)

    // ShortInt Tests
    s := 200;       (* $ExpectWarn 66 *)
    s := 12345;     (* $ExpectWarn 66 *)
    s := -12345;    (* $ExpectWarn 66 *)
    s := 123456;    (* $ExpectWarn 66 *)
    s := -123456;   (* $ExpectWarn 66 *)
    s := -123;
    s := b;         (* $ExpectWarn 66 *)
    s := w;         (* $ExpectWarn 66 *)
    s := i;         (* $ExpectWarn 66 *)
    s := c;         (* $ExpectWarn 66 *)
    s := l;         (* $ExpectWarn 66 *)
    s := r;         (* $ExpectError 38 *)
    s := -123.45;   (* $ExpectError 38 *)

    // Word Tests
    w := -123;      (* $ExpectWarn 66 *)
    w := -12345;    (* $ExpectWarn 66 *)
    w := 123456;    (* $ExpectWarn 66 *)
    w := -123456;   (* $ExpectWarn 66 *)
    w := 40000;
    w := b;
    w := s;         (* $ExpectWarn 66 *)
    w := i;         (* $ExpectWarn 66 *)
    w := c;         (* $ExpectWarn 66 *)
    w := l;         (* $ExpectWarn 66 *)
    w := r;         (* $ExpectError 38 *)
    w := 1234.56;   (* $ExpectError 38 *)

    // Integer Tests
    i := 40000;     (* $ExpectWarn 66 *)
    i := 123456;    (* $ExpectWarn 66 *)
    i := -123456;   (* $ExpectWarn 66 *)
    i := -12345;
    i := b;
    i := s;
    i := w;         (* $ExpectWarn 66 *)
    i := c;         (* $ExpectWarn 66 *)
    i := l;         (* $ExpectWarn 66 *)
    i := r;         (* $ExpectError 38 *)
    i := 1234.56;   (* $ExpectError 38 *)

    // Cardinal Tests
    c := -123;      (* $ExpectWarn 66 *)
    c := -12345;    (* $ExpectWarn 66 *)
    c := -123456;   (* $ExpectWarn 66 *)
    c := 123456;
    c := b;
    c := s;         (* $ExpectWarn 66 *)
    c := w;
    c := i;         (* $ExpectWarn 66 *)
    c := l;         (* $ExpectWarn 66 *)
    c := r;         (* $ExpectError 38 *)
    c := 1234.56;   (* $ExpectError 38 *)

    // LongInt Tests
    l := 2247483647;(* $ExpectWarn 66 *)
    l := -123456;
    l := s;
    l := b;
    l := w;
    l := i;
    l := c;         (* $ExpectWarn 66 *)
    l := r;         (* $ExpectError 38 *)
    l := 1234.56;   (* $ExpectError 38 *)

    // Boolean Tests
    bool := 123;    (* $ExpectError 38 *)
    bool := 3.14;   (* $ExpectError 38 *)
    bool := 0;      (* $ExpectError 38 *)
    bool := 'x';    (* $ExpectError 38 *)
    bool := 'abc';  (* $ExpectError 38 *)

    // Real Tests
    r := true;      (* $ExpectError 38 *)
    r := 'x';       (* $ExpectError 38 *)
    r := 'abc';     (* $ExpectError 38 *)

    // Char Tests
    ch := 123;      (* $ExpectError 38 *)
    ch := 3.14;     (* $ExpectError 38 *)
    ch := 'abc';    (* $ExpectError 38 *)
    ch := true;     (* $ExpectError 38 *)

    // String tests
    str := 12345;   (* $ExpectError 38 *)
    str := 3.14;    (* $ExpectError 38 *)
    str := true;    (* $ExpectError 38 *)
End.
