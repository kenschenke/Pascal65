Program FileTest;

Var
	anyErrors : Boolean;
    ch : Char;

Procedure Error(num : Integer);
Begin
    Writeln('FileTest (', num, ')');
    anyErrors := true;
End;

Procedure TestNotAssigned;
Var f : Text;
Begin
    Rewrite(f);
    If IOResult <> 102 Then Error(105);
    Reset(f);
    If IOResult <> 102 Then Error(106);
End;

Procedure TestNotFound;
Var f : Text;
Begin
    Assign(f, 'missing');
    Reset(f);
    If IOResult <> 2 Then Error(100);
End;

Procedure TestNotOpen;
Var
    ft : Text;
    fi : File Of Integer;
    i : Integer;
    s : String;
Begin
    Assign(ft, 'fnotest');
    Assign(fi, 'fnoint');

    Writeln(ft, 'Test');
    If IOResult <> 103 Then Error(107);
    Write(fi, 12345);
    If IOResult <> 103 Then Error(108);

    Readln(ft, s);
    If IOResult <> 103 Then Error(109);
    Read(fi, i);
    If IOResult <> 104 Then Error(110);

    Close(ft);
    If IOResult <> 103 Then Error(111);
End;

Procedure TestNotOpenForReading;
Var
    ft : Text;
    fi : File Of Integer;
    i : Integer;
    s : String;
Begin
    Assign(ft, 'fnortest');
    Rewrite(ft);
    Assign(fi, 'fnorint');
    Rewrite(fi);

    Readln(ft, s);
    If IOResult <> 104 Then Error(112);
    Read(fi, i);
    If IOResult <> 104 Then Error(113);

    Close(ft);
    Close(fi);
End;

Procedure TestNotOpenForWriting;
Var
    ft : Text;
    fi : File Of Integer;
Begin
    Assign(ft, 'fnowtest');
    Rewrite(ft);
    Assign(fi, 'fnowint');
    Rewrite(fi);

    Close(ft);
    Close(fi);
    Reset(ft);
    Reset(fi);

    Writeln(ft, 'Test Output');
    If IOResult <> 105 Then Error(114);
    Write(fi, 12345);
    If IOResult <> 105 Then Error(115);

    Close(ft);
    Close(fi);
End;

Procedure TestInvalidFilename;
Var f : Text;
Begin
    Assign(f, 'filenameistoolong');
    If IOResult <> 7 Then Error(101);
    Assign(f, 'file*name');
    If IOResult <> 7 Then Error(102);
    Assign(f, 'file?name');
    If IOResult <> 7 Then Error(103);
    Assign(f, 'validfn');
    If IOResult <> 0 Then Error(104);
End;

Procedure TestTooManyOpen;
Var
    files : Array[1..10] Of Text;
    i : ShortInt;
Begin
    For i := 1 To 10 Do Assign(files[i], WriteStr('file', i));

    For i := 1 To 9 Do Begin
        Rewrite(files[i]);
        If IOResult <> 0 Then Error(30);
    End;
    Rewrite(files[10]);
    If IOResult <> 4 Then Error(31);

    For i := 1 To 9 Do Close(files[i]);
End;

Procedure TestFileCurrentlyOpen;
Var f : Text;
Begin
    Assign(f, 'openfile');
    Rewrite(f);
    Rename(f, 'newopen');
    If IOResult <> 106 Then Error(40);
    Erase(f);
    If IOResult <> 106 Then Error(41);
    Rewrite(f);
    If IOResult <> 106 Then Error(42);
    Reset(f);
    If IOResult <> 106 Then Error(43);
    Close(f);
End;

Begin
	anyErrors := false;

	Writeln('Running');

    TestNotFound;
    TestInvalidFilename;
    TestNotAssigned;
    TestNotOpen;
    TestNotOpenForReading;
    TestNotOpenForWriting;
    TestFileCurrentlyOpen;
    TestTooManyOpen;

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey;
    End;
End.
