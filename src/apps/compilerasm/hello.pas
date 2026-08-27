Program EnumTest;

Type
    Colors = (Red, Green, Blue);
    Weekdays = (Monday, Tuesday, Wednesday);

Var
    color, otherColor : Colors;
    today : Weekdays;

(*
    Things to test:
    
    Things that work:
       * Ord
       * Pred
       * Succ
       * Case
       * If
       * Procedure with enum
       * Function returning enum
*)

Procedure SayColor(c : Colors);
Begin
    Case c Of
        Red: Write('Red');
        Green: Write('Green');
        Blue: Write('Blue');
    End;
End;

Function NextColor(c : Colors) : Colors;
Begin
    NextColor := Succ(c);
End;

Begin
    color := Green;
    today := Tuesday;
    If Ord(color) <> 1 Then Writeln('Error(1)');
    otherColor := Pred(color);
    If otherColor <> Red Then Writeln('Error(2)');
    otherColor := Succ(color);
    If otherColor <> Blue Then Writeln('Error(3)');

    // These two should not be generating compiler errors
    // If Pred(color) <> Red Then Writeln('Error(2)');
    // If Succ(color) <> Blue Then Writeln('Error(3)');
    
    Write('color is ');
    SayColor(color);
    Writeln(' (should say Green)');
    If NextColor(color) <> Blue Then Writeln('Error(4)');
    If color <> Green Then Writeln('Error(5)');
    If color = Red Then Writeln('Error(6)');
    Writeln('Done');

    // Compiler errors:
    // color := Tuesday;
    // today := NextColor(Wednesday);
    // today := NextColor(color);  // this did not generate an error
    // Case today Of
    //     Monday: Begin End;
    //     Red: Begin End;
    // End;
End.
