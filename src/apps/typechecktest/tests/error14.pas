// Error Test 14 - If, While, Repeat and Case statements
//
// A condition must be a Boolean. A Case selector is an integer, a Char
// or an enumeration, and its labels are constants of the same kind.
//
// The parser doesn't take an $Expect directive between two case branches,
// so a branch with one has a compound statement.

Program Stmts;

Type
    Color = (Red, Green, Blue);
    Shade = (Light, Dark);
    Small = 1..10;

Const
    Three = 3;

Var
    i : Integer;
    r : Real;
    ch : Char;
    c : Color;
    s : Small;
    bool : Boolean;

Begin
    If bool Then i := 1 Else i := 2;
    If i Then i := 1;               (* $ExpectError 30 *)
    If i Then i := 1 Else i := 2;   (* $ExpectError 30 *)
    While bool Do i := 1;
    While i Do i := 1;              (* $ExpectError 30 *)
    Repeat i := 1 Until bool;
    Repeat i := 1 Until i;          (* $ExpectError 30 *)

    Case ch Of
        'a': i := 1;
        'b', 'c': i := 2;
        1: Begin i := 3; (* $ExpectError 35 *) End;
    End;

    Case c Of
        Red: i := 1;
        Green, Blue: i := 2;
        Dark: Begin i := 3; (* $ExpectError 35 *) End;
    End;

    Case Green Of
        Red: i := 1;
    End;

    Case i Of
        1: i := 1;
        Three: i := 2;
        i: Begin i := 3; (* $ExpectError 33 *) End;
        'x': Begin i := 4; (* $ExpectError 35 *) End;
    End;

    Case s Of
        1, 2: i := 1;
        Three: i := 2;
    End;

    Case r Of 1: Begin i := 1; (* $ExpectError 35 *) End; End;
    Case bool Of 1: Begin (* $ExpectError 35 *) (* $ExpectError 35 *) End; End;
End.
