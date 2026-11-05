// Error Test 6 - For loop control variables

Program TestFor;

Type
    Color = (Red, Green, Blue);
    Letters = 'a'..'e';
    Small = 1..5;

Var
    b : Byte;
    i : Integer;
    l : LongInt;
    c : Char;
    k : Color;
    lt : Letters;
    sm : Small;
    r : Real;
    bool : Boolean;

Begin
    // Integers, characters, enumerations and their subranges are allowed
    For b := 1 To 10 Do i := 1;
    For i := -5 To b Do i := 1;
    For l := 100000 Downto 1 Do i := 1;
    For c := 'a' To 'z' Do i := 1;
    For c := 'z' Downto c Do i := 1;
    For k := Red To Blue Do i := 1;
    For k := Blue Downto k Do i := 1;
    For lt := 'b' To 'd' Do i := 1;
    For sm := 1 To 5 Do i := 1;

    // The final value must be of the same kind as the control variable
    For c := 'a' To 5 Do i := 1;            (* $ExpectError 35 *)
    For k := Red To 'x' Do i := 1;          (* $ExpectError 35 *)
    For i := 1 To 'z' Do i := 1;            (* $ExpectError 35 *)
    For i := 1 To Blue Do i := 1;           (* $ExpectError 35 *)
    For i := 1 To 2.5 Do i := 1;            (* $ExpectError 30 *)

    // Anything else is an error
    For r := 1.0 To 2.0 Do i := 1;          (* $ExpectError 30 *)
    For bool := False To True Do i := 1;    (* $ExpectError 30 *)
End.
