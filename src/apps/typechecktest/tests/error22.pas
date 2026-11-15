// Error Test 22 - Constant expressions
//
// An expression of literals and constants warns only if its value doesn't
// fit. A positive literal under 128 is a ShortInt, so 4 * 12 is an
// Integer, but 48 fits a Word.

Program ConstExprs;

Const
    Nine = 9;
    Big = 300;
    Neg = -5;

Var
    b : Byte;
    s : ShortInt;
    w : Word;
    i : Integer;
    c : Cardinal;
    l : LongInt;

Procedure TestByte(b1 : Byte); Begin End;
Procedure TestWord(w1 : Word); Begin End;

Begin
    // Assignments
    w := 4 * 12;
    w := 4 + 12;
    w := 48 + Nine;
    w := Nine + 48;
    w := 4 * 12 + Nine;
    w := -(4 - 12);
    b := 4 * 12;
    b := 100 + 100;
    i := 4 * 12;
    c := 300 * 300;
    c := 65535 * 65535;
    s := -100 - 28;
    w := 12 - 4;
    b := 300 - 100;
    b := 200 + 100;         (* $ExpectWarn 66 *)
    b := Big;               (* $ExpectWarn 66 *)
    w := 1 - 5;             (* $ExpectWarn 66 *)
    w := Neg;               (* $ExpectWarn 66 *)
    w := -Nine;             (* $ExpectWarn 66 *)
    w := 3 - 1234;          (* $ExpectWarn 66 *)
    w := 300 * 300;         (* $ExpectWarn 66 *)
    l := 65535 * 65535;     (* $ExpectWarn 66 *)
    s := 100 + 100;         (* $ExpectWarn 66 *)
    s := -100 - 29;         (* $ExpectWarn 66 *)
    w := i + 1;             (* $ExpectWarn 66 *)
    // Past 32 bits, or a multiplication with an operand over 16 bits, the
    // value isn't worked out, and the type decides as before
    l := 3000000000 + 3000000000;   (* $ExpectWarn 66 *)
    c := 70000 * 2;                 (* $ExpectWarn 66 *)

    // Parameters
    TestWord(4 * 12);
    TestWord(48 + Nine);
    TestByte(Nine + Nine);
    TestWord(1 - 5);        (* $ExpectWarn 66 *)
    TestByte(Big + 1);      (* $ExpectWarn 66 *)

    // Comparisons
    If w = 4 * 12 Then Begin End;
    If 4 * 12 > w Then Begin End;
    If i = 4 * 12 Then Begin End;
    If c > 48 + Nine Then Begin End;
    If i > 1 - 5 Then Begin End;
    If w < 1 - 5 Then Begin End;        (* $ExpectWarn 67 *)
    If 1 - 5 < w Then Begin End;        (* $ExpectWarn 67 *)
    If w = Neg Then Begin End;          (* $ExpectWarn 67 *)
End.
