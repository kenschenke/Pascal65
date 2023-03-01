Program ScalarTest(input, output);

Var
    b, b2 : boolean;
    c, c2 : char;
    i, j : integer;
    r, s : real;

Begin
    i := 1234;
    r := 54.321;
    s := 2345;
    b := true;
    b2 := false;
    b := b2;
    c := 'k';
    c2 := 'j';
    c := c2;
    i := j;
    r := s;
    r := j;
End.
