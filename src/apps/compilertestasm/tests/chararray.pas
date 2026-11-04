Program CharArrayTest;

Var
    anyErrors : Boolean;
    errList : String;
    Dice : Array[1..6] Of
        Array[1..3] Of Array[1..3] Of Char =
        (
            ((' ', ' ', ' '), (' ', #$51, ' '), (' ', ' ', ' ')),
            ((#$51, ' ', ' '), (' ', ' ', ' '), (' ', ' ', #$51)),
            ((#$51, ' ', ' '), (' ', #$51, ' '), (' ', ' ', #$51)),
            ((#$51, ' ', #$51), (' ', ' ', ' '), (#$51, ' ', #$51)),
            ((#$51, ' ', #$51), (' ', #$51, ' '), (#$51, ' ', #$51)),
            ((#$51, #$51, #$51), (' ', ' ', ' '), (#$51, #$51, #$51)),
        );
    T : Array[1..2] Of Array[1..2] Of Array[1..2] Of Char =
        ((('a', 'b'), ('c', 'd')), (('e', 'f'), ('g', 'h')));
    W : Array[1..2] Of Array[1..3] Of Array[1..3] Of Char;
    B : Array[1..3] Of Char = ('a', 'b', 'c');
    D : Array[1..2] Of Array[1..2] Of Char =
        (('p', 'q'), ('r', 's'));

Procedure Error(num : Integer);
Begin
    Writeln('CharArray (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

// Passing an array element to a Char parameter
Procedure Check(num : Integer; ch : Char; expected : Char);
Begin
    If ch <> expected Then Error(num);
End;

Procedure TestDirect;
Begin
    Check(100, Dice[1,2,2], #$51);
    Check(101, Dice[2,1,1], #$51);
    Check(102, Dice[2,1,3], ' ');
    Check(103, Dice[6,3,3], #$51);
    Check(104, Dice[1,1,1], ' ');
End;

Procedure TestOther;
Begin
    W[2,3,1] := 'z';
    Check(300, W[2,3,1], 'z');
    Check(310, B[1], 'a');
    Check(311, B[3], 'c');
    Check(320, D[1,2], 'q');
    Check(321, D[2,1], 'r');
    Check(400, T[1,1,1], 'a');
    Check(401, T[1,2,2], 'd');
    Check(402, T[2,1,2], 'f');
    Check(403, T[2,2,1], 'g');
    Check(404, T[2,2,2], 'h');
End;

Procedure TestLoop(num : Byte);
Var r, c, n : Byte;
Begin
    n := 0;
    For r := 1 To 3 Do
        For c := 1 To 3 Do
            If Dice[num,r,c] = #$51 Then n := n + 1;
    If (num = 1) And (n <> 1) Then Error(200);
    If (num = 3) And (n <> 3) Then Error(201);
    If (num = 6) And (n <> 6) Then Error(202);
    c := 2;
    Check(220, Dice[1,2,c], #$51);
    If num <> 6 Then Check(221, Dice[num,1,c], ' ');
    r := 2;
    Check(222, Dice[1,r,2], #$51);
    Check(223, Dice[1,r,c], #$51);
    For c := 1 To 3 Do Check(230, Dice[6,1,c], #$51);
End;

Procedure ReportFailure;
Var
    f : Text;
    acc : String;
Begin
    // Keep entries from earlier tests
    acc := '';
    Assign(f, 'testfailed');
    Reset(f);
    If IOResult = 0 Then Readln(f, acc);
    Close(f);
    If Length(acc) < 150 Then acc := acc + 'chararray:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running char array tests');

    TestDirect;
    TestOther;
    TestLoop(1);
    TestLoop(3);
    TestLoop(6);

    If anyErrors Then ReportFailure;
End.
