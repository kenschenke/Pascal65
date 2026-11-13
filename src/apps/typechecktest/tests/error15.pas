// Error Test 15 - Standard routines
//
// The number and types of the arguments of Abs, Sqr, Pred, Succ, Ord,
// Round, Trunc, Inc, Dec, Eoln and ReadStr. A function whose call has an
// error has no type, so assigning it is an error too.

Program StdRtns;

Type
    Color = (Red, Green, Blue);
    PInt = ^Integer;

Const
    Ten = 10;

Var
    i : Integer;
    l : LongInt;
    r : Real;
    ch : Char;
    c : Color;
    p : PInt;
    str : String;
    bool : Boolean;

Begin
    // Abs and Sqr
    l := Sqr(i);
    r := Sqr(r);
    i := Abs(i, i);     (* $ExpectError 50 *) (* $ExpectError 38 *)
    r := Sqr(r, r);     (* $ExpectError 50 *) (* $ExpectError 38 *)
    i := Abs(ch);       (* $ExpectError 30 *) (* $ExpectError 38 *)
    i := Sqr(str);      (* $ExpectError 30 *) (* $ExpectError 38 *)

    // Pred and Succ
    i := Succ(i);
    i := Succ(5);
    i := Pred(1000);
    l := Succ(100000);
    ch := Succ(ch);
    ch := Pred('b');
    c := Succ(c);
    c := Pred(Green);
    i := Succ(i, i);    (* $ExpectError 50 *) (* $ExpectError 38 *)
    i := Pred(i + 1);   (* $ExpectError 30 *) (* $ExpectError 38 *)
    r := Succ(r);       (* $ExpectError 35 *) (* $ExpectError 38 *)
    bool := Pred(bool); (* $ExpectError 35 *) (* $ExpectError 38 *)

    // Ord, Round and Trunc
    i := Ord(ch);
    i := Ord(c);
    i := Ord(i);
    i := Ord(ch, ch);               (* $ExpectError 50 *)
    i := Ord(r);                    (* $ExpectError 35 *)
    i := Round(r);
    i := Trunc(r);
    i := Trunc(ch);                 (* $ExpectError 35 *)

    // Inc and Dec
    Inc(i);
    Inc(i, 2);
    Dec(ch);
    Dec(c);
    Inc(p);
    Inc(r);                         (* $ExpectError 30 *)
    Inc(Ten);                       (* $ExpectError 30 *)
    Dec(i, r);                      (* $ExpectError 30 *)
    Inc(i, 1, 2);                   (* $ExpectError 50 *)

    // Eoln (not implemented, so it has no type)
    bool := Eoln;                   (* $ExpectError 38 *)

    // ReadStr
    ReadStr(str, i, ch);
    ReadStr(i, i);                  (* $ExpectError 35 *)

    // No arguments
    i := Abs();         (* $ExpectError 50 *) (* $ExpectError 38 *)
    i := Succ();        (* $ExpectError 50 *) (* $ExpectError 38 *)
    i := Ord();                     (* $ExpectError 50 *)
    i := Round();                   (* $ExpectError 50 *)
    Inc();                          (* $ExpectError 50 *)
    ReadStr();                      (* $ExpectError 50 *)
End.
