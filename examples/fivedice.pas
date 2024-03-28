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
        RollInHand : Integer;  (* 1, 2, or 3 *)
    End;
    Scores : Array[0..14] Of Integer;
    Dice : Array[1..6] Of
        Array[1..3] Of Array[1..3] Of Char;

Procedure CalcScore;
Var
    i : Integer;
Begin
    Game.TotalScore := 0;
    Scores[UpperBonus] := 0;
    For i := Aces To Sixes Do
        If Scores[i] >= 0 Then Game.TotalScore := Game.TotalScore + Scores[i];
    If Game.TotalScore >= UpperBonusCeiling Then
        Scores[UpperBonus] := UpperBonusScore;
    Game.TotalScore := Game.TotalScore + Scores[UpperBonus];
    Game.TotalUpper := Game.TotalScore;
    i := UpperBonus;
    While i <= FiveBonus Do Begin
        If Scores[i] >= 0 Then
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

Procedure DrawInstructions;
Var
    ch : Char;
    fill : String;
    i : Byte;
Begin
    DrawText(3, 5, 'welcome to five dice!');
    
    DrawText(5, 7, 'this game is inspired by the popular');
    DrawText(5, 8, 'board game where the player rolls five');
    DrawText(5, 9, 'dice and attempts to build poker hands.');

(*
    DrawText(5, 11, 'the scorecard is shown at the right.');
    DrawText(5, 12, 'each hand is started by rolling all dice.');

    DrawText(5, 14, 'the player decides which dice to keep');
    DrawText(5, 15, 'and which to roll for a better hand.');
    DrawText(5, 16, 'at any time the player can decide to');
    DrawText(5, 17, 'play their hand in one of the scores');
    DrawText(5, 18, 'on the right. up to three roles per hand');
    DrawText(5, 19, 'are allowed to build the strongest');
    DrawText(5, 20, 'possible hand. the game is over once all');
    DrawText(5, 21, 'scores are filled in.');
*)

    DrawText(5, 23, 'press a key to begin.');

    ch := GetKey;
    fill := StringOfChar(' ', 43);
    For i := 5 To 21 Do DrawText(3, i, fill);
End;

Procedure DrawScore(col, row : Byte; score : Integer);
Begin
    If score < 0 Then
        DrawText(col, row, '  -')
    Else
        DrawText(col, row, WriteStr(score:3));
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
    DrawScore(col, 5, Scores[Aces]);
    SetTextColor(GetScoreColor(Twos));
    DrawScore(col, 6, Scores[Twos]);
    SetTextColor(GetScoreColor(Threes));
    DrawScore(col, 7, Scores[Threes]);
    SetTextColor(GetScoreColor(Fours));
    DrawScore(col, 8, Scores[Fours]);
    SetTextColor(GetScoreColor(Fives));
    DrawScore(col, 9, Scores[Fives]);
    SetTextColor(GetScoreColor(Sixes));
    DrawScore(col, 10, Scores[Sixes]);
    SetTextColor(7);
    DrawScore(col, 11, Scores[UpperBonus]);
    DrawScore(col, 12, Game.TotalUpper);

    SetTextColor(GetScoreColor(ThreeOfAKind));
    DrawScore(col, 14, Scores[ThreeOfAKind]);
    SetTextColor(GetScoreColor(FourOfAKind));
    DrawScore(col, 15, Scores[FourOfAKind]);
    SetTextColor(GetScoreColor(FullHouse));
    DrawScore(col, 16, Scores[FullHouse]);
    SetTextColor(GetScoreColor(SmStraight));
    DrawScore(col, 17, Scores[SmStraight]);
    SetTextColor(GetScoreColor(LgStraight));
    DrawScore(col, 18, Scores[LgStraight]);
    SetTextColor(GetScoreColor(FiveOfAKind));
    DrawScore(col, 19, Scores[FiveOfAKind]);
    SetTextColor(GetScoreColor(Chance));
    DrawScore(col, 20, Scores[Chance]);
    SetTextColor(GetScoreColor(FiveBonus));
    DrawScore(col, 21, Scores[FiveBonus]);

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
    For i := 0 To NumScores-1 Do Scores[i] := -1;
    Game.TotalScore := 0;
    Game.TotalUpper := 0;
    Game.RollInHand := 0;
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
    Dice[6,3,3] := Chr($51);
End;

Procedure ShowDice;
Var
    i : Integer;
Begin
    For i := 1 To 5 Do Begin
        DrawDie(Game.DiceValues[i], i*8+3, 5);
    End;
End;

Procedure RunGame;
Var
    ch : Char;
    i : Integer;
Begin
    DrawText(5, 20, 'press space to roll dice');
    For i := 1 To 5 Do Game.DiceToRoll[i] := True;
    Repeat
        ch := GetKey;
        Case ch Of
            ' ': Begin
                RollDice;
                ShowDice;
            End;
        End;
    Until False;
End;

Begin
    ResetGame;
    SetupDice;

    ClearScreen;
    SetUpperCase;
    SetBackgroundColor(0);
    SetBorderColor(0);

    DrawGameBoard;
    DrawInstructions;
    RunGame;
    DrawDie(1, 5, 5);
    DrawDie(2, 13, 5);
    DrawDie(3, 21, 5);
    DrawDie(4, 5, 11);
    DrawDie(5, 13, 11);
    DrawDie(6, 21, 11);
End.
