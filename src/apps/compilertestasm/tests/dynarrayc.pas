Program DynArrayC;

// Tests SetLength on a dynamic array of records. A new record's strings,
// arrays and records must be initialized.

Type
    TPoint = Record
        x, y : Integer;
        lbl : String;
    End;
    TItem = Record
        id : Integer;
        name : String;
        vals : Array[1..3] Of Integer;
        pt : TPoint;
        tag : String;
    End;

Var
    anyErrors : Boolean;
    errList : String;
    i : Integer;
    items : Array Of TItem;

Procedure Error(num : Integer);
Begin
    Writeln('DynArrayC (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure CheckNewItem(num, n : Integer);
Begin
    If items[n].id <> 0 Then Error(num);
    If Length(items[n].name) <> 0 Then Error(num + 1);
    If Length(items[n].tag) <> 0 Then Error(num + 2);
    If Low(items[n].vals) <> 1 Then Error(num + 3);
    If High(items[n].vals) <> 3 Then Error(num + 4);
    For i := 1 To 3 Do
        If items[n].vals[i] <> 0 Then Error(num + 5);
    If items[n].pt.x <> 0 Then Error(num + 6);
    If Length(items[n].pt.lbl) <> 0 Then Error(num + 7);
End;

Procedure SetItem(n : Integer);
Begin
    items[n].id := n + 1;
    items[n].name := WriteStr('name', n);
    items[n].tag := WriteStr('tag', n);
    items[n].vals[1] := n * 3;
    items[n].vals[2] := n * 3 + 1;
    items[n].vals[3] := n * 3 + 2;
    items[n].pt.x := n + 50;
    items[n].pt.y := n + 60;
    items[n].pt.lbl := WriteStr('lbl', n);
End;

// Checks that items[n] has the values SetItem gave it
Procedure CheckItem(num, n : Integer);
Begin
    If items[n].id <> n + 1 Then Error(num);
    If CompareStr(items[n].name, WriteStr('name', n)) <> 0 Then
        Error(num + 1);
    If CompareStr(items[n].tag, WriteStr('tag', n)) <> 0 Then Error(num + 2);
    If items[n].vals[1] <> n * 3 Then Error(num + 3);
    If items[n].vals[3] <> n * 3 + 2 Then Error(num + 4);
    If items[n].pt.x <> n + 50 Then Error(num + 5);
    If items[n].pt.y <> n + 60 Then Error(num + 6);
    If CompareStr(items[n].pt.lbl, WriteStr('lbl', n)) <> 0 Then
        Error(num + 7);
End;

Procedure TestRecords;
Begin
    If Length(items) <> 0 Then Error(60);
    SetLength(items, 2);
    If Length(items) <> 2 Then Error(61);
    CheckNewItem(100, 0);
    CheckNewItem(110, 1);
    SetItem(0);
    SetItem(1);

    // Grow
    SetLength(items, 4);
    If Length(items) <> 4 Then Error(62);
    CheckItem(120, 0);
    CheckItem(130, 1);
    CheckNewItem(140, 2);
    CheckNewItem(150, 3);
    SetItem(2);
    SetItem(3);
    CheckItem(160, 3);

    // Shrink
    SetLength(items, 1);
    If Length(items) <> 1 Then Error(63);
    CheckItem(170, 0);

    // Grow again
    SetLength(items, 3);
    CheckItem(180, 0);
    CheckNewItem(190, 1);
    CheckNewItem(200, 2);

    SetLength(items, 0);
    If Length(items) <> 0 Then Error(64);
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
    If Length(acc) < 150 Then acc := acc + 'dynarrayc:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running dynamic array tests C');

    TestRecords;

    If anyErrors Then ReportFailure;
End.
