// Error Test 7 - SetLength, Length, Low, and High

Program TestArrayRtns;

Type
    TDyn = Array Of Integer;
    PDyn = ^TDyn;

Var
    a : Array Of Integer;
    d : TDyn;
    s : Array[1..10] Of Integer;
    c : Array Of Char;
    b : Byte;
    i : Integer;
    l : LongInt;
    r : Real;
    str : String;
    p : PDyn;

Begin
    // Valid calls
    SetLength(a, 10);
    SetLength(d, b);
    SetLength(c, l);
    SetLength(a, i + 1);
    i := Length(a);
    i := Length(s);
    i := Length(d);
    i := Length(c);
    i := Low(a) + High(a);
    i := Low(s) + High(s);
    For i := Low(d) To High(d) Do d[i] := i;
    b := Length(str);
    i := Length('abc');

    // Length of an array is an Integer
    b := Length(a);             (* $ExpectWarn 66 *)
    b := High(s);               (* $ExpectWarn 66 *)

    // SetLength
    SetLength(a);               (* $ExpectError 50 *)
    SetLength(a, 1, 2);         (* $ExpectError 50 *)
    SetLength(s, 5);            (* $ExpectError 30 *)
    SetLength(i, 5);            (* $ExpectError 30 *)
    SetLength(str, 5);          (* $ExpectError 30 *)
    SetLength(a, r);            (* $ExpectError 30 *)
    SetLength(a, 'x');          (* $ExpectError 30 *)
    SetLength(a, str);          (* $ExpectError 30 *)
    SetLength(5, 5);            (* $ExpectError 30 *)
    // The array must be named, not a pointer dereference
    SetLength(p^, 5);           (* $ExpectError 30 *)
    i := Length(p^);

    // Length
    b := Length(a, s);          (* $ExpectError 50 *)
    b := Length(str, a);        (* $ExpectError 50 *)
    b := Length(i);             (* $ExpectError 30 *)

    // Low and High
    i := Low(a, s);             (* $ExpectError 50 *)
    i := High(d, 1);            (* $ExpectError 50 *)
    i := Low(i);                (* $ExpectError 30 *)
    i := High(str);             (* $ExpectError 30 *)
    i := High(r);               (* $ExpectError 30 *)
End.
