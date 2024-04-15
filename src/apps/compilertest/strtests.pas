(* String Tests *)

Program StrTests;

Var
    anyErrors : Boolean;
    arr : Array[1..4] Of Char;
    ch : Char;
    str, str2 : String;

Procedure Error(num : Integer);
Begin
    Writeln('StrTests (', num, ')');
    anyErrors := true;
End;

Function StrTest1 : String;
Begin
    StrTest1 := 'Test1';
End;

Procedure StrTest2(s : String);
Begin
    If CompareStr(s, 'Test2') <> 0 Then Error(13);
End;

Procedure StrTest3(Var s3 : String);
Begin
    If CompareStr(s3, 'Test3') <> 0 Then Error(14);
    s3 := 'Test32';
End;

Begin
    anyErrors := false;

    Writeln('Running');

    str := 'Test';
    If CompareStr(str, 'Test') <> 0 Then Error(1);

    str2 := str;
    If CompareStr(str2, 'Test') <> 0 Then Error(2);
    If CompareStr(str, str2) <> 0 Then Error(3);

    str := 'Test' + ' ' + 'Test2';
    If CompareStr(str, 'Test Test2') <> 0 Then Error(4);

    str := 'Test';
    If CompareStr(str + ' ' + 'Test2', 'Test Test2') <> 0 Then Error(5);

    str := Chr(65) + 'bc';
    If CompareStr(str, 'abc') <> 0 Then Error(6);

    str := 'Test';
    str := str + ' Test2';
    If CompareStr(str, 'Test Test2') <> 0 Then Error(7);

    str := 'a';
    If CompareStr(str, 'a') <> 0 Then Error(8);

    arr[1] := 'T';
    arr[2] := 'e';
    arr[3] := 's';
    arr[4] := 't';
    str := arr;
    If CompareStr(str, 'Test') <> 0 Then Error(9);
    If CompareStr(arr, str) <> 0 Then Error(10);
    
    str := StrTest1;
    If CompareStr(str, 'Test1') <> 0 Then Error(11);
    If CompareStr(StrTest1, str) <> 0 Then Error(12);

    StrTest2('Test2');
    str := 'Test2';
    StrTest2(str);

    str := 'Test3';
    StrTest3(str);
    If CompareStr(str, 'Test32') <> 0 Then Error(15);

    str := 'Test4';
    If str[2] <> 'e' Then Error(16);
    If str[4] <> 't' Then Error(17);
    str[1] := 'W';
    If CompareStr(str, 'West4') <> 0 Then Error(18);
    str[3] := 'm';
    If CompareStr(str, 'Wemt4') <> 0 Then Error(19);

    If anyErrors Then Begin
        Write('Press a key to continue: ');
        ch := GetKey();
    End;
End.
