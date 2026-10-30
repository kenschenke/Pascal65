(* Case Tests *)

Program CaseTest;

Const
    IntValue = 1234;
    Letter = 'x';

Type
    Months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);

Var
    anyErrors, caseError : Boolean;
    errList : String;
    i : Integer;
    c : Char;
    m : Months;

Procedure Error(num : Integer);
Begin
    Writeln('Case (', num, ')');
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
    If Length(acc) < 150 Then acc := acc + 'casetest:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running case tests');

    i := 1234;
    caseError := true;
    Case i Of
        1023, 1025: Error(1);
        1233, 1234: caseError := false;
    End;
    If caseError Then Error(2);

    caseError := true;
    Case i Of
        1, 2, 3: Error(3);
        IntValue: caseError := false;
    End;
    If caseError Then Error(4);

    c := 'x';
    caseError := true;
    Case c Of
        'a', 'b', 'c': Error(5);
        'w', 'x', 'y': caseError := false;
        'z': Error(6);
    End;
    If caseError Then Error(7);

    caseError := true;
    Case c Of
        'a', 'b': Error(8);
        Letter: caseError := false;
    End;
    If caseError Then Error(9);

    m := Oct;
    caseError := true;
    Case m Of
        Jan, Feb, Mar: Error(10);
        Sep, Oct, Nov: caseError := false;
    End;
    If caseError Then Error(11);

    m := Feb;
    Case m Of
        Apr, May, Jun: Error(12);
        Feb: caseError := false;
    End;
    If caseError Then Error(13);

    If anyErrors Then ReportFailure;
End.
