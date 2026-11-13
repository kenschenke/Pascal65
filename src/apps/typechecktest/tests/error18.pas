// Error Test 18 - Read, Readln, Write, Writeln and WriteStr
//
// The variables Read can read into and the values Write can write, with
// and without a file. A record needs a file. A file that isn't first is
// reported, and so is its type, which the arguments after it are
// checked against.

Program ReadWrite;

Type
    Color = (Red, Green, Blue);
    TRec = Record a : Integer; End;
    TOther = Record a : Integer; End;
    TArr = Array[1..3] Of Byte;
    TStr = String;

Var
    b : Byte;
    sh : ShortInt;
    w : Word;
    i : Integer;
    c : Cardinal;
    l : LongInt;
    r : Real;
    ch : Char;
    bool : Boolean;
    str : String;
    col : Color;
    rec : TRec;
    other : TOther;
    arr : TArr;
    chars : Array[1..5] Of Char;
    nums : Array[1..5] Of Integer;
    pi : ^Integer;
    ps : ^TStr;
    fi : File Of Integer;
    fr : File Of TRec;
    fa : File Of TArr;
    t : Text;

Begin
    // Read
    Read(b, sh, w, i, c, l, r, ch, bool, str);
    Read(chars);
    Read(nums);                     (* $ExpectError 35 *)
    Read(arr[1]);
    Read(pi^);
    Read(col);                      (* $ExpectError 35 *)
    Read(rec);                      (* $ExpectError 35 *)
    Read(i + 1);                    (* $ExpectError 51 *)
    Read(fi, i);
    Read(fi, str);                  (* $ExpectError 35 *)
    Read(fr, rec);
    Read(fa, arr);
    Read(i, fi);        (* $ExpectError 35 *) (* $ExpectError 35 *)
    Readln(fi, i);                  (* $ExpectError 35 *)
    Read(t, i);
    Read(i, t);                     (* $ExpectError 35 *)
    ReadStr(str, t);                (* $ExpectError 35 *)
    ReadStr(ps^, i);

    // Write
    Write(b, r, ch, bool, 'abc', str, str + str, i);
    Write(chars);
    Write(nums);                    (* $ExpectError 35 *)
    Write(pi);                      (* $ExpectError 35 *)
    Write(rec);                     (* $ExpectError 35 *)
    Write(fi, i);
    Write(fi, 'abc');               (* $ExpectError 35 *)
    Write(fr, rec);
    Write(fr, other);               (* $ExpectError 35 *)
    Write(fa, arr);
    Write(i, fi);       (* $ExpectError 35 *) (* $ExpectError 35 *)
    Writeln(fi, i);                 (* $ExpectError 35 *)
    Write(t, i);
    Write(i, t);                    (* $ExpectError 35 *)
    str := WriteStr(t);             (* $ExpectError 35 *)
End.
