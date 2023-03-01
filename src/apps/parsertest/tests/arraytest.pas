Program ArrayTest(input, output);

Type
    en = (one, two, three, four, five);
 
Var
    ab : array [1..6] of boolean;
    ac : array [0..10] of char;
    ai : array [-5..5] of integer;
    ar : array [0..3] of real;
    ae : array [-5..0] of en;
    ae2 : array [en] of integer;
    ae3 : array [(alpha, beta, gamma)] of real;
    al : array ['a'..'z'] of boolean;
    an : array [1..10] of
        array['m'..'r'] of real;
    b : boolean;
    c : char;
    i : integer;
    r : real;
    e : en;
 
Begin
    ab[1] := true;
    ab[i] := false;
    ac[0] := 'c';
    ai[-2] := 12345;
    ar[1] := 3.14159;
    ae[0] := one;
    ae2[three] := -5;
    ae3[gamma] := 3.14;
    an[5]['t'] := 54.321;
    ab[2] := b;
    ac[3] := c;
    ai[1] := i;
    ar[2] := r;
    ae[-1] := e;
    ae2[four] := 12;
    al['c'] := true;
    b := ab[3];
    c := ac[6];
    i := ai[-2];
    r := ar[1];
    e := ae[-4];
End.
