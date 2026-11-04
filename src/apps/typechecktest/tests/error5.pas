// Error Test 5 - Write, Writeln, and WriteStr field width and precision

Program TestWidth;

Var
    b : Byte;
    s : ShortInt;
    w : Word;
    i : Integer;
    c : Cardinal;
    l : LongInt;
    r : Real;
    bool : Boolean;
    ch : Char;
    str : String;

Function FieldWidth(n : Byte) : Word;
Begin
    FieldWidth := n + 1;
End;

Begin
    // Any size integer is allowed for the width and precision
    Writeln(i:b);
    Writeln(i:s);
    Writeln(i:w);
    Writeln(i:i);
    Writeln(i:c);
    Writeln(i:l);
    Writeln(r:b:b);
    Writeln(r:s:s);
    Writeln(r:w:w);
    Writeln(r:i:i);
    Writeln(r:c:c);
    Writeln(r:l:l);
    Write(ch:b, bool:w, str:c, 'abc':l);
    str := WriteStr(i:b + s, r:w * 2:c - l);
    Writeln(i:200, i:12345, i:123456, r:-5:FieldWidth(b));
    Writeln(i:b:w);

    // Anything else is an error
    Writeln(i:r);               (* $ExpectError 35 *)
    Writeln(i:bool);            (* $ExpectError 35 *)
    Writeln(i:ch);              (* $ExpectError 35 *)
    Writeln(i:str);             (* $ExpectError 35 *)
    Writeln(i:'abc');           (* $ExpectError 35 *)
    Writeln(r:6:r);             (* $ExpectError 35 *)
    Writeln(r:6:1.5);           (* $ExpectError 35 *)
    Write(str:r);               (* $ExpectError 35 *)
    Write(ch:bool);             (* $ExpectError 35 *)
    str := WriteStr(i:r);       (* $ExpectError 35 *)
End.
