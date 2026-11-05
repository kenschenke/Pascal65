Program DynArrayA;

// Tests dynamic arrays: SetLength on arrays of scalars, strings and
// reals, and Length, Low and High. dynarrayb and dynarrayc have the rest.

Type
    TIntArr = Array Of Integer;
    TStrArr = Array Of String;

Var
    anyErrors : Boolean;
    errList : String;
    i : Integer;
    ints : TIntArr;
    empty : TIntArr;
    strs : TStrArr;
    reals : Array Of Real;
    stat : Array[5..9] Of Integer;

Procedure Error(num : Integer);
Begin
    Writeln('DynArrayA (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

Procedure TestEmpty;
Begin
    If Length(empty) <> 0 Then Error(1);
    If Low(empty) <> 0 Then Error(2);
    If High(empty) <> -1 Then Error(3);
End;

Procedure TestStatic;
Begin
    If Length(stat) <> 5 Then Error(10);
    If Low(stat) <> 5 Then Error(11);
    If High(stat) <> 9 Then Error(12);
End;

Procedure TestInts;
Begin
    SetLength(ints, 5);
    If Length(ints) <> 5 Then Error(20);
    If Low(ints) <> 0 Then Error(21);
    If High(ints) <> 4 Then Error(22);
    For i := 0 To 4 Do
        If ints[i] <> 0 Then Error(23);
    For i := 0 To 4 Do ints[i] := i * 10 + 1;

    // Grow: the elements are kept and the new ones are zero
    SetLength(ints, 10);
    If Length(ints) <> 10 Then Error(24);
    If High(ints) <> 9 Then Error(25);
    For i := 0 To 4 Do
        If ints[i] <> i * 10 + 1 Then Error(26);
    For i := 5 To 9 Do
        If ints[i] <> 0 Then Error(27);

    // Shrink
    SetLength(ints, 3);
    If Length(ints) <> 3 Then Error(28);
    If High(ints) <> 2 Then Error(29);
    For i := 0 To 2 Do
        If ints[i] <> i * 10 + 1 Then Error(30);

    // To zero and back
    SetLength(ints, 0);
    If Length(ints) <> 0 Then Error(31);
    If High(ints) <> -1 Then Error(32);
    SetLength(ints, 4);
    If Length(ints) <> 4 Then Error(33);
    For i := 0 To 3 Do
        If ints[i] <> 0 Then Error(34);
    For i := 0 To 3 Do ints[i] := i + 100;
End;

Procedure TestStrings;
Begin
    SetLength(strs, 3);
    If Length(strs) <> 3 Then Error(40);
    For i := 0 To 2 Do
        If Length(strs[i]) <> 0 Then Error(41);
    strs[0] := 'one';
    strs[1] := 'two';
    strs[2] := 'three';

    // Grow: the new strings are empty
    SetLength(strs, 5);
    If Length(strs) <> 5 Then Error(42);
    If CompareStr(strs[0], 'one') <> 0 Then Error(43);
    If CompareStr(strs[1], 'two') <> 0 Then Error(44);
    If CompareStr(strs[2], 'three') <> 0 Then Error(45);
    If Length(strs[3]) <> 0 Then Error(46);
    If Length(strs[4]) <> 0 Then Error(47);
    strs[4] := 'five';

    // Shrink, then grow again
    SetLength(strs, 2);
    If Length(strs) <> 2 Then Error(48);
    If CompareStr(strs[1], 'two') <> 0 Then Error(49);
    SetLength(strs, 4);
    If CompareStr(strs[0], 'one') <> 0 Then Error(50);
    If Length(strs[2]) <> 0 Then Error(51);
    If Length(strs[3]) <> 0 Then Error(52);
    strs[3] := 'four';
    If CompareStr(strs[3], 'four') <> 0 Then Error(53);

    SetLength(strs, 0);
    If Length(strs) <> 0 Then Error(54);
    SetLength(strs, 2);
    If Length(strs[0]) <> 0 Then Error(55);
    strs[0] := 'first';
    strs[1] := 'second';
End;

// Checks that items[n] is a new, empty record
Procedure TestReals;
Begin
    SetLength(reals, 3);
    reals[0] := 1.5;
    reals[2] := 2.5;
    SetLength(reals, 6);
    If Length(reals) <> 6 Then Error(70);
    If reals[0] <> 1.5 Then Error(71);
    If reals[2] <> 2.5 Then Error(72);
    reals[5] := 3.5;
    If reals[5] <> 3.5 Then Error(73);
    SetLength(reals, 1);
    If reals[0] <> 1.5 Then Error(74);
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
    If Length(acc) < 150 Then acc := acc + 'dynarraya:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running dynamic array tests A');

    TestEmpty;
    TestStatic;
    TestInts;
    TestStrings;
    TestReals;

    If anyErrors Then ReportFailure;
End.
