// Error Test 10 - ReadStr and files of dynamic arrays

Program TestReadStrFiles;

Const
    k = 5;

Type
    TD = Array Of Integer;
    TStat = Array[1..5] Of Integer;
    TStatFile = File Of TStat;

Var
    i : Integer;
    ch : Char;
    s : String;
    ca : Array[1..10] Of Char;
    dc : Array Of Char;
    r : Real;
    tf : Text;
    sf : File Of TStat;
    sf2 : TStatFile;

// A file can't hold dynamic arrays, written out or named
Procedure P1;
Var f : File Of Array Of Integer; Begin i := 1; (* $ExpectError 73 *) End;
Procedure P2; Var f : File Of TD; Begin i := 1; (* $ExpectError 73 *) End;
// Reported once, for the type and not the variable
Procedure P3;
Type F = File Of TD; Var g : F; Begin i := 1; (* $ExpectError 73 *) End;

Begin
    // Valid calls
    ReadStr(s, i, ch, r, s, ca, dc);
    ReadStr('12 34', i, i);
    ReadStr(ca, s);
    ReadStr(dc, s);
    ReadStr(s + 'x', i);
    ReadStr('x', ch);
    ReadStr(ch, ch);
    ReadStr(s);

    // The source must be a string
    ReadStr(i, s);              (* $ExpectError 35 *)
    ReadStr(r, i);              (* $ExpectError 35 *)

    // ReadStr doesn't read files
    ReadStr(s, tf);             (* $ExpectError 35 *)
    ReadStr(s, sf);             (* $ExpectError 35 *)

    // It reads into variables
    ReadStr(s, k);              (* $ExpectError 35 *)
    ReadStr(s, i + 1);          (* $ExpectError 51 *)
End.
