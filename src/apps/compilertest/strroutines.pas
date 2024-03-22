(* String Routine Tests *)

Program StrRoutines;

Var
    anyErrors : Boolean;
    ch : Char;

Procedure Error(num : Integer);
Begin
    Writeln('StrRoutines (', num, ')');
    anyErrors := true;
End;

Begin
    anyErrors := false;

    Writeln('Running');

    If CompareStr('', '') <> 0 Then Error(1);
    If CompareStr('test', 'test') <> 0 Then Error(2);
    If CompareStr('test', 'tests') >= 0 Then Error(3);
    If CompareStr('test', '') <= 0 Then Error(4);
    If CompareStr('', 'test') >= 0 Then Error(5);
    If CompareStr('abc', 'def') >= 0 Then Error(6);
    If CompareStr('def', 'abc') <= 0 Then Error(7);

    If Length('') <> 0 Then Error(8);
    If Length('Hello World') <> 11 Then Error(9);

    If CompareStr(LowerCase('Hello'), 'hello') <> 0 Then Error(10);

    If CompareStr(StringOfChar('x', 5), 'xxxxx') <> 0 Then Error(11);

    If CompareStr(Trim('abcdef'), 'abcdef') <> 0 Then Error(12);
    If CompareStr(Trim('   abcdef   '), 'abcdef') <> 0 Then Error(13);
    If CompareStr(Trim(' abc def '), 'abc def') <> 0 Then Error(14);

    If CompareStr(UpCase('Hello'), 'HELLO') <> 0 Then Error(15);

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey();
    End;
End.
