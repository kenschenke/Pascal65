(* Case Tests *)

Program Loops;
Const
    IntValue = 1234;
    Letter = 'x';
    LoveMonth = Feb;

Type
    Months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);

Var
    anyErrors, caseError : Boolean;
    i : Integer;
    c : Char;
    m : Months;

Procedure Error(num : Integer);
Begin
    Writeln('Case (', num, ')');
    anyErrors := true;
End;

Begin
    anyErrors := false;

    Writeln('Running');

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
        LoveMonth: caseError := false;
    End;
    If caseError Then Error(13);

    If anyErrors Then Begin
        Write('Type any number to continue: ');
        Readln(i);
    End;
End.
