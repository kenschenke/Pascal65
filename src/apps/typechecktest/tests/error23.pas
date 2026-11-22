// Error Test 23 - String comparison operands
//
// A string operand (a String, a string literal, a string object, an array
// of Char or a Char) compares with another string operand. With anything
// else it is one errIncompatibleTypes. An array of String isn't a string
// operand. A Char with a Char, or a Char subrange, is ordinal.

Program StrComp;

Type
    Rec = Record
        s : String;
        a : Array[1..4] Of Char;
    End;
    Letter = 'a'..'z';
    Str = String;
    Color = (Red, Green, Blue);

Var
    s : String;
    al : Str;
    r : Rec;
    e : Array[1..3] Of String;
    ac : Array[1..4] Of Char;
    ab : Array[-2..2] Of Char;
    ai : Array[1..4] Of Integer;
    c : Char;
    l : Letter;
    ps : ^String;
    pint : ^Integer;
    col : Color;
    i : Integer;
    re : Real;
    bool : Boolean;

Procedure P(Var vs : String; ws : String);
Begin
    bool := vs < ws;
    bool := ws >= vs;
    bool := vs = 'abc';
End;

Begin
    // Operand forms that compare as strings
    bool := r.s = s;
    bool := s <> r.s;
    bool := r.a < s;
    bool := e[2] > s;
    bool := s <= e[2];
    bool := ps^ >= s;
    bool := al = s;
    bool := s = al;
    bool := ac = ab;
    bool := ab < ac;
    bool := l = s;
    bool := s <> l;
    bool := s = '';
    bool := 'abc' < 'abd';
    bool := s[1] = s;
    bool := s + 'x' = 'a' + s;

    // Ordinal comparisons
    bool := c = 'y';
    bool := s[1] < 'x';
    bool := l <= c;
    bool := c > l;

    // A string operand with anything else
    bool := s = i;          (* $ExpectError 35 *)
    bool := i < s;          (* $ExpectError 35 *)
    bool := s = re;         (* $ExpectError 35 *)
    bool := s <> True;      (* $ExpectError 35 *)
    bool := s = nil;        (* $ExpectError 35 *)
    bool := nil <> s;       (* $ExpectError 35 *)
    bool := s = ps;         (* $ExpectError 35 *)
    bool := pint = s;       (* $ExpectError 35 *)
    bool := s = r;          (* $ExpectError 35 *)
    bool := s = ai;         (* $ExpectError 35 *)
    bool := ac = i;         (* $ExpectError 35 *)
    bool := 5 > ac;         (* $ExpectError 35 *)
    bool := 'abc' = 1;      (* $ExpectError 35 *)
    bool := c = 1;          (* $ExpectError 35 *)
    bool := s = col;        (* $ExpectError 35 *)
    bool := e = s;          (* $ExpectError 35 *)
    bool := s < e;          (* $ExpectError 35 *)
End.
