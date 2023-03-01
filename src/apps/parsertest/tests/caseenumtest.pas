Program CaseEnum(input, output);

Type
    en = (apple, banana, cherry, kiwi, lemon, pear);

Var
    e : en;

Begin
    Case e Of
        apple: writeln(10);
        banana, cherry: Begin
            writeln(10 + 3);
            writeln(100 div 7);
        End;
        kiwi, lemon, pear: writeln(20 * 9);
    End;
End.
