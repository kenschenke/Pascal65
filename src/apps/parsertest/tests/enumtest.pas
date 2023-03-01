Program EnumTest(input, output);

Type
    en = (alpha, beta, gamma);
    aen = array[en] of real;
    ar = array[(one, two, three, four, five)] of integer;
 
Var
    ae : array[en] of integer;
    a1 : aen;
    an : ar;
    af : array[(apple, banana, lemon)] of boolean;
    ee, ef : en;
 
Begin
    ee := beta;
    ef := ee;
    ae[gamma] := 123;
    a1[gamma] := 3.14159;
    an[four] := 543;
    af[apple] := true;
End.
