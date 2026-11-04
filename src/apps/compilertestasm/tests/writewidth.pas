// Write Field Width and Precision Tests
//
// The field width and precision can be an expression of any size integer.

Program WriteWidth;

Var
    anyErrors : Boolean;
    errList : String;
    b : Byte;
    si : ShortInt;
    w : Word;
    i : Integer;
    c : Cardinal;
    li : LongInt;

Procedure Error(num : Integer);
Begin
    Writeln('WriteWidth (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
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
    If Length(acc) < 150 Then acc := acc + 'writewidth:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running write width tests');

    b := 5;
    si := 4;
    w := 6;
    i := 3;
    c := 7;
    li := 8;

    // Field width of each integer type
    If CompareStr(WriteStr(123:b), '  123') <> 0 Then Error(1);
    If CompareStr(WriteStr(123:si), ' 123') <> 0 Then Error(2);
    If CompareStr(WriteStr(123:w), '   123') <> 0 Then Error(3);
    If CompareStr(WriteStr(123:i), '123') <> 0 Then Error(4);
    If CompareStr(WriteStr(123:c), '    123') <> 0 Then Error(5);
    If CompareStr(WriteStr(123:li), '     123') <> 0 Then Error(6);

    // Field width expressions
    If CompareStr(WriteStr(123:b + si - i), '   123') <> 0 Then Error(7);
    If CompareStr(WriteStr(123:Length('abcde')), '  123') <> 0
        Then Error(8);
    If CompareStr(WriteStr(123:5000 - 4995), '  123') <> 0 Then Error(9);
    If CompareStr(WriteStr(123:100000 - 99994), '   123') <> 0
        Then Error(10);

    // Field width and precision of different integer types
    If CompareStr(WriteStr(1.358:c:si - 2), '   1.36') <> 0 Then Error(11);
    If CompareStr(WriteStr(1.358:b + 1:w - 4), '  1.36') <> 0
        Then Error(12);
    If CompareStr(WriteStr(1.358:li:i - 1), '    1.36') <> 0 Then Error(13);
    If CompareStr(WriteStr(1.358:6:c - 5), '  1.36') <> 0 Then Error(14);
    If CompareStr(WriteStr(1.358:w:b - 3), '  1.36') <> 0 Then Error(15);

    If anyErrors Then ReportFailure;
End.
