CONST
    ten       = 10;
    minusten  = -ten;
    hundred   = 100;
    maxlength = 80;
    ch        = 'x';
    hello     = 'Hello, world.';

TYPE
    e  = (alpha, beta, gamma);
    ee = e;
    sr = alpha..gamma;
    cr = 'a'..ch;

    ar1 = ARRAY [1..-minusten] OF integer;
    ar3 = ARRAY [(fee, fye, foe, fum), ten..hundred] OF
        ARRAY [ee] OF boolean;
    ar4 = ARRAY [boolean, 'm'..'r'] OF char;

    rec1 = RECORD
        i  : integer;
        ch : char;
    END;

    rec2 = RECORD
        a  : ar1;
        r  : rec1;
        rr : RECORD
            i : integer;
            b : boolean;
        END;
    END;
    