Program FileTest;

Type
    ShortArray = Array[1..5] Of ShortInt;
    TestRec = Record
        sh : ShortInt;
        int : Integer;
        ch : Char;
    End;

Var
	anyErrors : Boolean;
    ch : Char;

Procedure Error(num : Integer);
Begin
    Writeln('FileTest (', num, ')');
    anyErrors := true;
End;

Procedure TestArrayFile;
Var
    f : File Of ShortArray;
    arr : ShortArray;
    i, j : ShortInt;
Begin
    Assign(f, 'arrfile');
    Rewrite(f);
    For i := 1 To 3 Do Begin
        For j := 1 To 5 Do arr[j] := i*2 + j;
        Write(f, arr);
    End;
    Close(f);

    Reset(f);
    For i := 1 To 3 Do Begin
        Read(f, arr);
        For j := 1 To 5 Do Begin
            If arr[j] <> i*2 + j Then Error(116);
        End;
    End;
    If Not Eof(f) Then Error(117);
    Close(f);
End;

Procedure TestRecordFile;
Var
    f : File Of TestRec;
    rec : TestRec;
    i : ShortInt;
Begin
    Assign(f, 'recfile');
    Rewrite(f);
    For i := 1 To 3 Do Begin
        rec.sh := i;
        rec.int := i * 2;
        rec.ch := Chr(Ord('a') + i);
        Write(f, rec);
    End;
    Close(f);

    Reset(f);
    For i := 1 To 3 Do Begin
        Read(f, rec);
        If rec.sh <> i Then Error(118);
        If rec.int <> i * 2 Then Error(119);
        If Ord(rec.ch) <> Ord('a')+i Then Error(120);
    End;
    If Not Eof(f) Then Error(121);
    Close(f);
End;

Procedure TestIntFile;
Var
    f : File Of Integer;
    i, j : Integer;
Begin
    Assign(f, 'intfile');
    Rewrite(f);
    For i := 1234 To 1238 Do Write(f, i);
    Close(f);

    Reset(f);
    i := 1234;
    While Not Eof(f) Do Begin
        Read(f, j);
        If i <> j Then Error(20);
        Inc(i);
    End;
    Close(f);
    If i <> 1239 Then Error(21);
End;

Procedure TestText;
Var
    f : Text;
    s : String;
    i : Integer;
Begin
    Assign(f, 'testtext');
    Rewrite(f);
    For i := 1 To 5 Do Writeln(f, 'Test Line ', i);
    Close(f);

    Reset(f);
    For i := 1 To 5 Do Begin
        Readln(f, s);
        If CompareStr(s, WriteStr('Test Line ', i)) <> 0 Then Error(10);
    End;
    If Not Eof(f) Then Error(11);
    Close(f);
End;

Procedure TestOverwrite;
Var
    f : Text;
    s : String;
Begin
    Assign(f, 'overwrite.txt');
    Rewrite(f);
    Writeln(f, 'first file');
    Close(f);

    Rewrite(f);
    Writeln(f, 'second file');
    Close(f);

    Reset(f);
    Readln(f, s);
    If CompareStr(s, 'second file') <> 0 Then Error(32);
End;

Procedure TestErase;
Var f : Text;
Begin
    Assign(f, 'testerase');
    Rewrite(f);
    Writeln(f, 'test file');
    Close(f);

    Erase(f);
    Reset(f);
    If IOResult <> 2 Then Error(33);
End;

Procedure TestRename;
Var
    f, f2 : Text;
    s : String;
Begin
    Assign(f, 'oldname');
    Rewrite(f);
    Writeln(f, 'old file');
    Close(f);

    Rename(f, 'newname');
    If IOResult <> 0 Then Error(34);
    Reset(f);
    If IOResult <> 0 Then Error(35);
    Readln(f, s);
    If CompareStr(s, 'old file') <> 0 Then Error(36);
    Close(f);

    Assign(f2, 'newname');
    If IOResult <> 0 Then Error(37);
    Reset(f2);
    If IOResult <> 0 Then Error(38);
    Readln(f2, s);
    If CompareStr(s, 'old file') <> 0 Then Error(39);
    Close(f2);

    Reset(f);
    If IOResult <> 0 Then Error(381);
    Readln(f, s);
    If CompareStr(s, 'old file') <> 0 Then Error(39);
    Close(f);

    Assign(f, 'missing');
    Rename(f, 'wontwork');
    If IOResult <> 2 Then Error(391);
End;

Begin
	anyErrors := false;

	Writeln('Running');

	TestText;
    TestIntFile;
    TestArrayFile;
    TestRecordFile;
    TestOverwrite;
    TestErase;
    TestRename;

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
