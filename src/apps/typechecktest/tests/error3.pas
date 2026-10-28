// Error Test 3 - Procedure Call Precision Loss Warnings

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

Procedure TestByte(b1 : Byte); Begin End;
Procedure TestShortInt(s1 : ShortInt); Begin End;
Procedure TestWord(w1 : Word); Begin End;
Procedure TestInteger(i1 : Integer); Begin End;
Procedure TestCardinal(c1 : Cardinal); Begin End;
Procedure TestLongInt(l1 : LongInt); Begin End;
Procedure TestBoolean(b1 : Boolean); Begin End;
Procedure TestReal(r1 : Real); Begin End;
Procedure TestChar(c1 : Char); Begin End;
Procedure TestString(s1 : String); Begin End;

Begin
    // Byte Tests
    TestByte(-123);         (* $ExpectWarn 66 *)
    TestByte(12345);        (* $ExpectWarn 66 *)
    TestByte(-12345);       (* $ExpectWarn 66 *)
    TestByte(123456);       (* $ExpectWarn 66 *)
    TestByte(-123456);      (* $ExpectWarn 66 *)
    TestByte(200);
    TestByte(s);            (* $ExpectWarn 66 *)
    TestByte(w);            (* $ExpectWarn 66 *)
    TestByte(i);            (* $ExpectWarn 66 *)
    TestByte(c);            (* $ExpectWarn 66 *)
    TestByte(l);            (* $ExpectWarn 66 *)
    TestByte(r);            (* $ExpectError 30 *)
    TestByte(123.45);       (* $ExpectError 30 *)

    // ShortInt Tests
    TestShortInt(200);      (* $ExpectWarn 66 *)
    TestShortInt(12345);    (* $ExpectWarn 66 *)
    TestShortInt(-12345);   (* $ExpectWarn 66 *)
    TestShortInt(123456);   (* $ExpectWarn 66 *)
    TestShortInt(-123456);  (* $ExpectWarn 66 *)
    TestShortInt(-123);
    TestShortInt(b);        (* $ExpectWarn 66 *)
    TestShortInt(w);        (* $ExpectWarn 66 *)
    TestShortInt(i);        (* $ExpectWarn 66 *)
    TestShortInt(c);        (* $ExpectWarn 66 *)
    TestShortInt(l);        (* $ExpectWarn 66 *)
    TestShortInt(r);        (* $ExpectError 30 *)
    TestShortInt(-123.45);  (* $ExpectError 30 *)

    // Word Tests
    TestWord(-123);         (* $ExpectWarn 66 *)
    TestWord(-12345);       (* $ExpectWarn 66 *)
    TestWord(123456);       (* $ExpectWarn 66 *)
    TestWord(-123456);      (* $ExpectWarn 66 *)
    TestWord(40000);
    TestWord(b);
    TestWord(s);            (* $ExpectWarn 66 *)
    TestWord(i);            (* $ExpectWarn 66 *)
    TestWord(c);            (* $ExpectWarn 66 *)
    TestWord(l);            (* $ExpectWarn 66 *)
    TestWord(r);            (* $ExpectError 30 *)
    TestWord(1234.56);      (* $ExpectError 30 *)

    // Integer Tests
    TestInteger(40000);     (* $ExpectWarn 66 *)
    TestInteger(123456);    (* $ExpectWarn 66 *)
    TestInteger(-123456);   (* $ExpectWarn 66 *)
    TestInteger(-12345);
    TestInteger(b);
    TestInteger(s);
    TestInteger(w);         (* $ExpectWarn 66 *)
    TestInteger(c);         (* $ExpectWarn 66 *)
    TestInteger(l);         (* $ExpectWarn 66 *)
    TestInteger(r);         (* $ExpectError 30 *)
    TestInteger(1234.56);   (* $ExpectError 30 *)

    // Cardinal Tests
    TestCardinal(-123);     (* $ExpectWarn 66 *)
    TestCardinal(-12345);   (* $ExpectWarn 66 *)
    TestCardinal(-123456);  (* $ExpectWarn 66 *)
    TestCardinal(123456);
    TestCardinal(b);
    TestCardinal(s)         (* $ExpectWarn 66 *)
    TestCardinal(w);
    TestCardinal(i);        (* $ExpectWarn 66 *)
    TestCardinal(l);        (* $ExpectWarn 66 *)
    TestCardinal(r);        (* $ExpectError 30 *)
    TestCardinal(1234.56);  (* $ExpectError 30 *)

    // LongInt Tests
    TestLongInt(2247483647);(* $ExpectWarn 66 *)
    TestLongInt(-123456);
    TestLongInt(s);
    TestLongInt(b);
    TestLongInt(w);
    TestLongInt(i);
    TestLongInt(c);         (* $ExpectWarn 66 *)
    TestLongInt(r);         (* $ExpectError 30 *)
    TestLongInt(1234.56);   (* $ExpectError 30 *)

    // Boolean Tests
    TestBoolean(123);       (* $ExpectError 30 *)
    TestBoolean(3.14);      (* $ExpectError 30 *)
    TestBoolean(0);         (* $ExpectError 30 *)
    TestBoolean('x');       (* $ExpectError 30 *)
    TestBoolean('abc');     (* $ExpectError 30 *)

    // Real Tests
    TestReal(true);         (* $ExpectError 30 *)
    TestReal('x');          (* $ExpectError 30 *)
    TestReal('abc');        (* $ExpectError 30 *)

    // Char Tests
    TestChar(123);          (* $ExpectError 30 *)
    TestChar(3.14);         (* $ExpectError 30 *)
    TestChar('abc');        (* $ExpectError 30 *)
    TestChar(true);         (* $ExpectError 30 *)

    // String tests
    TestString(12345);      (* $ExpectError 30 *)
    TestString(3.14);       (* $ExpectError 30 *)
    TestString(true);       (* $ExpectError 30 *)
End.
