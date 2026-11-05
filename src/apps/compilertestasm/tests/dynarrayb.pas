Program DynArrayB;

// Tests dynamic arrays: literals, local arrays, routine parameters and
// I/O of a dynamic array of Char. dynarraya and dynarrayc have the rest.

Type
    TItem = Record
        id : Integer;
        name : String;
        tag : String;
    End;
    TIntArr = Array Of Integer;
    TStrArr = Array Of String;

Var
    anyErrors : Boolean;
    errList : String;
    i : Integer;
    s : String;
    ints : TIntArr;
    strs : TStrArr;
    chars : Array Of Char;
    lits : TIntArr = (10, 20, 30);
    // A one-character literal ('a') in a string array initializer comes
    // out empty, for static arrays too, so these have two or more.
    slits : TStrArr = ('aa', 'bb', 'ccc');

Procedure Error(num : Integer);
Begin
    Writeln('DynArrayB (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure TestLiterals;
Begin
    If Length(lits) <> 3 Then Error(80);
    If Low(lits) <> 0 Then Error(81);
    If High(lits) <> 2 Then Error(82);
    If lits[0] <> 10 Then Error(83);
    If lits[1] <> 20 Then Error(84);
    If lits[2] <> 30 Then Error(85);
    SetLength(lits, 5);
    If lits[2] <> 30 Then Error(86);
    If lits[4] <> 0 Then Error(87);

    If Length(slits) <> 3 Then Error(88);
    If CompareStr(slits[0], 'aa') <> 0 Then Error(89);
    If CompareStr(slits[2], 'ccc') <> 0 Then Error(90);
    SetLength(slits, 4);
    If CompareStr(slits[1], 'bb') <> 0 Then Error(91);
    If Length(slits[3]) <> 0 Then Error(92);
End;

// A local dynamic array is freed when the routine returns
Procedure TestLocal(n : Integer);
Var
    a : TStrArr;
    b : Array Of TItem;
    j : Integer;
Begin
    If Length(a) <> 0 Then Error(300);
    SetLength(a, n);
    For j := 0 To n - 1 Do a[j] := WriteStr('local', j);
    If CompareStr(a[n - 1], WriteStr('local', n - 1)) <> 0 Then Error(301);
    SetLength(b, n);
    b[n - 1].name := 'local';
    If Length(b[0].tag) <> 0 Then Error(302);
End;

// The copy is independent of the caller's array
Procedure ByValue(a : TIntArr);
Begin
    If Length(a) <> 4 Then Error(310);
    If a[1] <> 101 Then Error(311);
    a[1] := 999;
    SetLength(a, 20);
    If Length(a) <> 20 Then Error(312);
    If a[1] <> 999 Then Error(313);
    If a[19] <> 0 Then Error(314);
End;

Procedure ByValueStr(a : TStrArr);
Begin
    If CompareStr(a[1], 'second') <> 0 Then Error(320);
    a[1] := 'changed';
    SetLength(a, 1);
End;

// SetLength on a Var parameter changes the caller's array
Procedure ByVar(Var a : TIntArr);
Begin
    If Length(a) <> 4 Then Error(330);
    SetLength(a, 7);
    a[6] := 66;
    a[0] := 77;
End;

Procedure ByVarStr(Var a : TStrArr);
Begin
    SetLength(a, 3);
    a[2] := 'third';
End;

Procedure TestParams;
Begin
    ByValue(ints);
    If Length(ints) <> 4 Then Error(340);
    If ints[1] <> 101 Then Error(341);

    ByValueStr(strs);
    If Length(strs) <> 2 Then Error(342);
    If CompareStr(strs[1], 'second') <> 0 Then Error(343);

    ByVar(ints);
    If Length(ints) <> 7 Then Error(344);
    If ints[0] <> 77 Then Error(345);
    If ints[3] <> 103 Then Error(346);
    If ints[5] <> 0 Then Error(347);
    If ints[6] <> 66 Then Error(348);

    ByVarStr(strs);
    If Length(strs) <> 3 Then Error(349);
    If CompareStr(strs[0], 'first') <> 0 Then Error(350);
    If CompareStr(strs[2], 'third') <> 0 Then Error(351);
End;

// Write and Read of a dynamic array of Char, through a text file.
// (WriteStr and ReadStr don't support character arrays, static or dynamic.)
Procedure TestChars;
Var
    tf : Text;
Begin
    Assign(tf, 'dynchars');

    // An empty array writes nothing
    Rewrite(tf);
    Writeln(tf, '[', chars, ']');
    Close(tf);
    Reset(tf);
    Readln(tf, s);
    Close(tf);
    If CompareStr(s, '[]') <> 0 Then Error(400);

    SetLength(chars, 5);
    chars[0] := 'h';
    chars[1] := 'e';
    chars[2] := 'l';
    chars[3] := 'l';
    chars[4] := 'o';
    Rewrite(tf);
    Write(tf, chars);
    Writeln(tf);
    Close(tf);
    Reset(tf);
    Readln(tf, s);
    Close(tf);
    If CompareStr(s, 'hello') <> 0 Then Error(401);

    // A longer array is filled with spaces. Readln uses up the line.
    SetLength(chars, 7);
    Reset(tf);
    Readln(tf, chars);
    Close(tf);
    If chars[4] <> 'o' Then Error(402);
    If chars[5] <> ' ' Then Error(403);
    If chars[6] <> ' ' Then Error(404);

    // Read into a shorter array. Read leaves the rest of the line in the
    // input buffer, even after Close, so this one comes last.
    SetLength(chars, 3);
    Reset(tf);
    Read(tf, chars);
    Close(tf);
    If Length(chars) <> 3 Then Error(405);
    If chars[0] <> 'h' Then Error(406);
    If chars[2] <> 'l' Then Error(407);
End;

Procedure ReportFailure;
Var
    f : Text;
    acc : String;
Begin
    // Keep entries from earlier tests
    acc := '';
    Assign(f, 'testfailed');
    Reset(f);
    If IOResult = 0 Then Readln(f, acc);
    Close(f);
    If Length(acc) < 150 Then acc := acc + 'dynarrayb:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running dynamic array tests B');

    // The parameter tests start from these
    SetLength(ints, 4);
    For i := 0 To 3 Do ints[i] := i + 100;
    SetLength(strs, 2);
    strs[0] := 'first';
    strs[1] := 'second';

    TestLiterals;
    For i := 1 To 5 Do TestLocal(i);
    TestParams;
    TestChars;

    If anyErrors Then ReportFailure;
End.
