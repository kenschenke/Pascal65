(* Clone of popular game involving five dice *)

Program FiveDice;

Uses Screen;

Const
    NumScores = 15;
    UpperBonusCeiling = 63;
    UpperBonusScore = 35;

    (* Offsets in Scores array *)
    Aces = 0;
    Twos = 1;
    Threes = 2;
    Fours = 3;
    Fives = 4;
    Sixes = 5;
    UpperBonus = 6;
    ThreeOfAKind = 7;
    FourOfAKind = 8;
    FullHouse = 9;
    SmStraight = 10;
    LgStraight = 11;
    FiveOfAKind = 12;
    Chance = 13;
    FiveBonus = 14;

Var
    Game : Record
        DiceValues : Array[1..5] Of Integer;
        DiceToRoll : Array[1..5] Of Boolean;
        TotalUpper : Integer;
        TotalScore : Integer;
    End;
    Scores : Array[0..14] Of Byte;
    Dice : Array[1..6] Of
        Array[1..3] Of Array[1..3] Of Char;

Procedure CalcScore;
Var
    i : Integer;
Begin
    Game.TotalScore := 0;
    For i := Aces To Sixes Do Game.TotalScore := Game.TotalScore + Scores[i];
    If Game.TotalScore >= UpperBonusCeiling Then
        Scores[UpperBonus] := UpperBonusScore;
    Game.TotalScore := Game.TotalScore + Scores[UpperBonus];
    Game.TotalUpper := Game.TotalScore;
    i := UpperBonus;
    While i <= FiveBonus Do Begin
        Game.TotalScore := Game.TotalScore + Scores[i];
        i := i + 1;
    End;
End;

Function GetScoreColor(score : Byte) : Byte;
Begin
    If Scores[score] > 0 Then
        GetScoreColor := 7
    Else
        GetScoreColor := 12;
End;

Procedure DrawDie(num, col, row : Byte);
Var r, c : Byte;
Begin
    DrawTextRaw(col, row, Chr($55) + StringOfChar(Chr($43), 5) + Chr($49));
    For r := 1 To 3 Do Begin
        DrawTextRaw(col, row+r, Chr($42) + ' ');
        For c:= 1 To 3 Do DrawCharRaw(col+c+1, row+r, Dice[num,r,c]);
        DrawTextRaw(col+5, row+r, ' ' + Chr($42));
    End;
    (*
    DrawTextRaw(col, row+1, Chr($42) + Dice[num,1] + Chr($42));
    DrawTextRaw(col, row+2, Chr($42) + Dice[num,2] + Chr($42));
    DrawTextRaw(col, row+3, Chr($42) + Dice[num,3] + Chr($42));
    *)
    DrawTextRaw(col, row+4, Chr($4a) + StringOfChar(Chr($43), 5) + Chr($4b));
End;

Procedure DrawGameBoard;
Var
    r, col : Byte;
Begin
    r := 5;
    col := 50;

    SetTextColor(1);
    DrawText(col,  5, 'a. aces');
    DrawText(col,  6, 'b. twos');
    DrawText(col,  7, 'c. threes');
    DrawText(col,  8, 'd. fours');
    DrawText(col,  9, 'e. fives');
    DrawText(col, 10, 'f. sixes');
    DrawText(col+3, 11, 'upper bonus');
    DrawText(col+3, 12, 'total upper');

    DrawText(col, 14, 'g. 3 of a kind');
    DrawText(col, 15, 'h. 4 of a kind');
    DrawText(col, 16, 'i. full house');
    DrawText(col, 17, 'j. sm. straight');
    DrawText(col, 18, 'k. lg. straight');
    DrawText(col, 19, 'l. five of a kind');
    DrawText(col, 20, 'm. chance');
    DrawText(col, 21, 'n. five kind bonus');

    DrawText(col+3, 23, 'total score');

    col := 69;

    CalcScore;

    SetTextColor(GetScoreColor(Aces));
    DrawText(col, 5, WriteStr(Scores[Aces]:3));
    SetTextColor(GetScoreColor(Twos));
    DrawText(col, 6, WriteStr(Scores[Twos]:3));
    SetTextColor(GetScoreColor(Threes));
    DrawText(col, 7, WriteStr(Scores[Threes]:3));
    SetTextColor(GetScoreColor(Fours));
    DrawText(col, 8, WriteStr(Scores[Fours]:3));
    SetTextColor(GetScoreColor(Fives));
    DrawText(col, 9, WriteStr(Scores[Fives]:3));
    SetTextColor(GetScoreColor(Sixes));
    DrawText(col, 10, WriteStr(Scores[Sixes]:3));
    SetTextColor(7);
    DrawText(col, 11, WriteStr(Scores[UpperBonus]:3));
    Drawtext(col, 12, WriteStr(Game.TotalUpper:3));

    SetTextColor(GetScoreColor(ThreeOfAKind));
    DrawText(col, 14, WriteStr(Scores[ThreeOfAKind]:3));
    SetTextColor(GetScoreColor(FourOfAKind));
    DrawText(col, 15, WriteStr(Scores[FourOfAKind]:3));
    SetTextColor(GetScoreColor(FullHouse));
    DrawText(col, 16, WriteStr(Scores[FullHouse]:3));
    SetTextColor(GetScoreColor(SmStraight));
    DrawText(col, 17, WriteStr(Scores[SmStraight]:3));
    SetTextColor(GetScoreColor(LgStraight));
    DrawText(col, 18, WriteStr(Scores[LgStraight]:3));
    SetTextColor(GetScoreColor(FiveOfAKind));
    DrawText(col, 19, WriteStr(Scores[FiveOfAKind]:3));
    SetTextColor(GetScoreColor(Chance));
    DrawText(col, 20, WriteStr(Scores[Chance]:3));
    SetTextColor(GetScoreColor(FiveBonus));
    DrawText(col, 21, WriteStr(Scores[FiveBonus]:3));

    SetTextColor(7);
    DrawText(col, 23, WriteStr(Game.TotalScore:3));
End;

Function MakeDiceValue : Integer;
Begin
    MakeDiceValue := Round((Peek($d7ef) / 256) * 5.0) + 1;
End;

Procedure ResetGame;
Var
    i : Byte;
Begin
    For i := 0 To NumScores-1 Do Scores[i] := 0;
    Game.TotalScore := 0;
    Game.TotalUpper := 0;
    For i := 1 To 5 Do Game.DiceToRoll[i] := false;
End;

Procedure RollDice;
Var
    i : Byte;
Begin
    For i := 1 To 5 Do Begin
        If Game.DiceToRoll[i] Then
            Game.DiceValues[i] := MakeDiceValue;
    End;
End;

Procedure SetupDice;
Var d, r, c : Integer;
Begin
    For d := 1 To 6 Do Begin
        For r := 1 To 3 Do Begin
            For c := 1 To 3 Do Dice[d,r,c] := ' ';
        End;
    End;

    Dice[1,2,2] := Chr($51);

    Dice[2,1,1] := Chr($51);
    Dice[2,3,3] := Chr($51);

    Dice[3,1,1] := Chr($51);
    Dice[3,2,2] := Chr($51);
    Dice[3,3,3] := Chr($51);

    Dice[4,1,1] := Chr($51);
    Dice[4,3,1] := Chr($51);
    Dice[4,1,3] := Chr($51);
    Dice[4,3,3] := Chr($51);

    Dice[5,1,1] := Chr($51);
    Dice[5,1,3] := Chr($51);
    Dice[5,2,2] := Chr($51);
    Dice[5,3,1] := Chr($51);
    Dice[5,3,3] := Chr($51);

    Dice[6,1,1] := Chr($51);
    Dice[6,1,2] := Chr($51);
    Dice[6,1,3] := Chr($51);
    Dice[6,3,1] := Chr($51);
    Dice[6,3,2] := Chr($51);
(*
    Dice[6,3,3] := Chr($51);
*)
End;

Begin
    ResetGame;
    SetupDice;

    ClearScreen;
    SetUpperCase;
    SetBackgroundColor(0);
    SetBorderColor(0);

    DrawGameBoard;
    DrawDie(1, 5, 5);
    DrawDie(2, 13, 5);
    DrawDie(3, 21, 5);
    DrawDie(4, 5, 11);
    DrawDie(5, 13, 11);
    DrawDie(6, 21, 11);
End.
