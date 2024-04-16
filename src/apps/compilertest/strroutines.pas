(* String Routine Tests *)

Program StrRoutines;

Var
    anyErrors : Boolean;
    ch : Char;
    str : String;

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

    If CompareStr(WriteStr(123:5, ' ', 1.358:6:2), '  123   1.36') <> 0
        Then Error(16);

    str := 'Hello World';
    If Not Contains(str, 'Hello') Then Error(17);
    If Not Contains(str, 'ello') Then Error(18);
    If Not Contains(str, 'World') Then Error(19);
    If Contains(str, 'ELLO') Then Error(20);
    If Contains(str, 'Hello, World') Then Error(21);
    If Not Contains(str, 'Hello World') Then Error(22);
    If Contains(str, 'Hellos') Then Error(23);
    If Contains(str, 'Worlds') Then Error(24);

    If Not BeginsWith(str, 'Hello') Then Error(25);
    If Not BeginsWith(str, 'Hello World') Then Error(26);
    If BeginsWith(str, 'Hello Worlds') Then Error(27);
    If BeginsWith(str, 'HEL') Then Error(28);
    If BeginsWith(str, 'World') Then Error(29);

    If Not EndsWith(str, 'World') Then Error(30);
    If Not EndsWith(str, 'Hello World') Then Error(31);
    If EndsWith(str, 'Hello Worlds') Then Error(32);
    If EndsWith(str, 'Hello') Then Error(33);
    If EndsWith(str, 'ello') Then Error(34);

    If StrPos(str, 'Hello', 1) <> 1 Then Error(35);
    If StrPos(str, 'Hello', 2) <> 0 Then Error(36);
    If StrPos(str, 'Hellos', 1) <> 0 Then Error(37);
    If StrPos(str, 'World', 1) <> 7 Then Error(38);
    If StrPos(str, 'World', 8) <> 0 Then Error(39);
    If StrPos(str, 'Hello World', 1) <> 1 Then Error(40);
    If StrPos(str, 'Hello World', 2) <> 0 Then Error(41);
    If StrPos(str, 'd', 0) <> 0 Then Error(42);
    If StrPos(str, 'd', 11) <> 11 Then Error(43);
    If StrPos(str, 'd', 12) <> 0 Then Error(44);

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey();
    End;
End.
