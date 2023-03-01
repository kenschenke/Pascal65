PROGRAM testprog(input, output);

CONST
    ten = 10;
    ch = 'x';
    pi = 3;
    hello = 'Hello, world.';

TYPE
    e = (alpha, beta, gamma);
    ee = e;
    sr = alpha..gamma;
    cr = 'a'..'x';
    ar1 = ARRAY [1..10] OF integer;
    array2 = ARRAY [(fee, fye, foe, fum)] OF
        ARRAY [1..100] OF
            ARRAY [e] OF
                ARRAY ['m'..'r'] OF
                    ARRAY [e] of boolean;
    
    rec = RECORD
        a : ar1;
        rr : RECORD
            i : integer;
            b : boolean;
        END;
    END;

VAR
    i, radius, circumference : integer;
    b : boolean;
    letter : 'a'..'z';
    myArray : ar1;
    a2 : array2;
    buffer : ARRAY [1..80] OF char;
    greek : e;
    myRec : rec;

PROCEDURE sayHello();
BEGIN
    writeln('Hello, world');
    a2[foe][50][gamma]['o'][beta] := false;
    writeln(hello);
END;

BEGIN
    radius := 5;
    circumference := 2 * pi * radius;
    letter := 's';

    FOR i := 1 TO 10 DO writeln(i);

    IF radius = 5 THEN BEGIN
        writeln('it''s five');
        i := 10;
    END ELSE BEGIN
        writeln('not five');
        i := 11;
    END;

    myArray[1] := 5;
    myArray[5] := 10;

    b := true;
    b := false;

    greek := gamma;

    myRec.a[6] := 11;
    myRec.rr.i := 12;
    myRec.rr.b := true;

    b := (radius <> 5) AND (i >= 5);

    IF ((radius <> 5) OR (i = 4)) AND NOT (circumference <= 10) THEN
        writeln('I be here');
    
    i := (5 + radius) * circumference;
    i := ord(gamma) MOD 2;

    REPEAT
        i := i + 1;
        writeln('in a loop');
    UNTIL i >= 10;

    WHILE i < 10 DO i := i + 1;

    WHILE i < 100 DO BEGIN
        i := i + 10;
        writeln('in another loop');
    END;

    CASE i OF
        1: writeln('it be one');
        2: writeln('it be two');
        3: BEGIN
            writeln('it be three');
            i := i + 1;
        END;
        4, 5, 6: writeln('ha!');
    END;

    case greek OF
        alpha: writeln('alpha');
        beta: writeln('beta');
    END;
END.
