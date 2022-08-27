BEGIN
    i := 0;
    total := 1;

    REPEAT
        total := total * 5;
        i := i + 1;
    UNTIL i > 5;

    output := total;
END.
