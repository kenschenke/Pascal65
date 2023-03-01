Program RecordTest(input, output);

Type
    En = (one, two, three, four, five);
    ScalarRec = Record
        b : boolean;
        c : char;
        e : en;
        i : integer;
        r : real;
    End;
    ArrayRec = Record
        a : array[1..10] of integer;
    End;
    NestedRec = Record
        j : integer;
        s : ScalarRec;
    End;
    NestedAnonRec = Record
        k : integer;
        d : Record
            f : boolean;
            t : real;
        End;
    End;
    Ar = array[0..5] of ScalarRec;
 
Var
    sr : ScalarRec;
    aar : ArrayRec;
    nr : NestedRec;
    na : NestedAnonRec;
    ara : ar;
 
Begin
    sr.b := true;
    sr.c := 'k';
    sr.e := three;
    sr.i := 123;
    sr.r := 543.21;
    aar.a[5] := 100;
    nr.j := 55;
    nr.s.b := false;
    nr.s.i := 25;
    na.k := 22;
    na.d.f := true;
    na.d.t := 98.6;
    ara[2].i := 101;
    ara[2].r := 2.1;
End.
