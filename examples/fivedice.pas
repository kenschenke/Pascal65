(*
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Clone of popular game involving five dice
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Program FiveDice;

Uses Screen;

Const
    RollsPerHand = 3;
    NumScores = 15;
    UpperBonusCeiling = 63;
    UpperBonusScore = 35;
    FullHouseScore = 25;
    SmStraightScore = 30;
    LgStraightScore = 40;
    FiveDiceScore = 50;
    FiveDiceBonusScore = 100;

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
    DiceTopRow, DiceBottomRow, DiceLeft, DiceRight : String;
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

    (* Used to count occurances of each dice value *)
    DiceCounts : Array[1..6] Of Byte;

Procedure DrawGameBoard; Forward;
Procedure ShowDice; Forward;

(* Count the number of dice for each possible value 1-6 *)
Procedure CalcDiceCounts;
Var
    i, v : Integer;
Begin
    For i := 1 To 6 Do DiceCounts[i] := 0;
    For i := 1 To 5 Do Begin
        v := Game.DiceValues[i];
        DiceCounts[v] := DiceCounts[v] + 1;
    End;
End;

(* Calculate player score and update Game.TotalScore variable *)
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

(*
    Calculate score of dice 1 through 5.
    Parameters:
        value: 1-5
        score: score offset in Scores[] array
*)
Procedure CalcFaceScore(value, score : Integer);
Var
    i, n : Integer;
Begin
    n := 0;
    For i := 1 To 5 Do
        If Game.DiceValues[i] = value Then n := n + 1;
    Scores[score] := n * value;
    CalcScore;
    DrawGameBoard;
End;

(*
    Calculates the total of all dice
*)
Function CalcDiceTotal : Integer;
Var i, total : Integer;
Begin
    total := 0;
    For i := 1 To 5 Do
        total := total + Game.DiceValues[i];
    CalcDiceTotal := total;
End;

(* This procedure clears the text prompts shown to the player
   during game play
*)
Procedure ClearPrompts;
Begin
    DrawText(5, 18, '                        ');
    DrawText(5, 20, '                        ');
    DrawText(5, 21, '                            ');
End;

(*
    This procedure is called when the player wants to score
    a five of a kind. If the player did score a five of a kind,
    it records that score. Otherwise, it records a zero.
*)
Procedure DoFiveDice;
Var
    Found : Boolean;
    i : Integer;
Begin
    Found := False;
    CalcDiceCounts;
    For i := 1 To 6 Do
        If DiceCounts[i] = 5 Then Found := True;
    If Found Then Begin
        If Scores[FiveOfAKind] = -1 Then
            Scores[FiveOfAKind] := FiveDiceScore
        Else If Scores[FiveOfAKind] > 0 Then
            Scores[FiveBonus] := Scores[FiveBonus] + FiveDiceBonusScore;
    End Else If Scores[FiveOfAKind] = -1 Then
        Scores[FiveOfAKind] := 0;
End;

(*
    This procedure is called when the player wants to score a full house.
    It verifies the player has a full house and scores it.
*)
Procedure DoFullHouse;
Var
    Found2, Found3 : Boolean;
    i : Integer;
Begin
    Found2 := False;
    Found3 := False;
    CalcDiceCounts;
    For i := 1 To 6 Do Begin
        If DiceCounts[i] = 3 Then Found3 := True;
        If DiceCounts[i] = 2 Then Found2 := True;
    End;
    If Found2 And Found3 Then
        Scores[FullHouse] := FullHouseScore
    Else
        Scores[FullHouse] := 0;
End;

(*
    This function is called when the player wants to score a three or
    four of a kind. It verifies the player has the hand and returns
    the score.
*)
Function DoXOfAKind(Threshold : Byte) : Integer;
Var
    i : Byte;
    found : Boolean;
Begin
    CalcDiceCounts;
    found := False;
    For i := 1 To 6 Do
        If DiceCounts[i] >= Threshold Then found := True;
    If found Then
        DoXOfAKind := CalcDiceTotal
    Else
        DoXOfAKind := 0;
End;

(*
    This procedure is called when the player wants to score a small straight.
    It verifies the player has a small straight and scores it.
*)
Procedure DoSmStraight;
Begin
    CalcDiceCounts;
    If (DiceCounts[3] = 0) Or (DiceCounts[4] = 0) Then
        Scores[SmStraight] := 0
    Else If (DiceCounts[1] > 0) And (DiceCounts[2] > 0) Then
        Scores[SmStraight] := SmStraightScore
    Else If (DiceCounts[2] > 0) And (DiceCounts[5] > 0) Then
        Scores[SmStraight] := SmStraightScore
    Else If (DiceCounts[5] > 0) And (DiceCounts[5] > 0) Then
        Scores[SmStraight] := SmStraightScore
    Else
        Scores[SmStraight] := 0;
End;

(*
    This procedure is called when the player wants to score a large straight.
    It verifies the player has a large straight and scores it.
*)
Procedure DoLgStraight;
Begin
    CalcDiceCounts;
    If (DiceCounts[2] = 0) Or
        (DiceCounts[3] = 0) Or
        (DiceCounts[4] = 0) Or
        (DiceCounts[5] = 0) Then
        Scores[LgStraight] := 0
    Else If DiceCounts[1] > 0 Then
        Scores[LgStraight] := LgStraightScore
    Else If DiceCounts[6] > 0 Then
        Scores[LgStraight] := LgStraightScore
    Else
        Scores[LgStraight] := 0;
End;

(* Returns color of score on screen *)
Function GetScoreColor(score : Byte) : Byte;
Begin
    If Scores[score] > 0 Then
        GetScoreColor := 7
    Else
        GetScoreColor := 12;
End;

(*
    Renders a die
    Parameters:
        num: 1-5
        col: column
        row: row
*)
Procedure DrawDie(num, col, row : Byte);
Var r, c : Byte;
Begin
    DrawTextRaw(col, row, DiceTopRow);
    For r := 1 To 3 Do Begin
        DrawTextRaw(col, row+r, DiceLeft);
        For c:= 1 To 3 Do DrawCharRaw(col+c+1, row+r, Dice[num,r,c]);
        DrawTextRaw(col+5, row+r, DiceRight);
    End;
    DrawTextRaw(col, row+4, DiceBottomRow);
End;

(* Renders instructions *)
Procedure DrawInstructions;
Var
    ch : Char;
    fill : String;
    i : Byte;
Begin
    DrawText(3, 5, 'welcome to five dice!');

    DrawText(5, 7, 'copyright 2024 by ken schenke');

    DrawText(5, 8, 'written using pascal65');
    DrawText(5, 9, 'github.com/kenschenke/pascal65');
    
    DrawText(5, 23, 'press a key to begin.');

    ch := GetKey;
    fill := StringOfChar(' ', 43);
    For i := 5 To 23 Do DrawText(3, i, fill);
End;

(*
    Renders a score. If score is < 0 then "-" is rendered.
    Parameters:
        col: column
        row: row
        score: score
*)
Procedure DrawScore(col, row : Byte; score : Integer);
Begin
    If score < 0 Then
        DrawText(col, row, '  -')
    Else
        DrawText(col, row, WriteStr(score:3));
End;

(* Renders the game board *)
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

(* This function looks at the scores and determines
   whether or not the player has filled all possible scores. *)
Function IsGameDone : Boolean;
Var
    i : Integer;
Begin
    IsGameDone := True;
    For i := Aces To Chance Do
        If Scores[i] = -1 Then IsGameDone := False;
End;

(* Returns a random value between 1 and 6 *)
Function MakeDiceValue : Integer;
Begin
    MakeDiceValue := Round((Peek($d7ef) / 256) * 5.0) + 1;
End;

(* Resets game values and scores *)
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

(* Generates random values for dice flagged to roll *)
Procedure RollDice;
Var
    i : Byte;
Begin
    For i := 1 To 5 Do Begin
        If Game.DiceToRoll[i] Then
            Game.DiceValues[i] := MakeDiceValue;
    End;
    Game.RollInHand := Game.RollInHand + 1;
    ShowDice;
End;

(* Draws the prompt to roll dice *)
Procedure ShowRollDicePrompt;
Begin
    DrawText(5, 20, 'press space to roll dice');
End;

(* Resets game state and screen for the next hand *)
Procedure SetNextHand;
Var
    i : Byte;
Begin
    For i := 1 To 5 Do Game.DiceToRoll[i] := True;
    Game.RollInHand := 0;
    For i := 5 To 10 Do
        DrawText(2, i, '                                        ');
    ShowRollDicePrompt;
    RollDice;
End;

(* This procedure sets up the strings to render dice *)
Procedure SetUpDice;
Begin
    DiceTopRow := Chr($55) + StringOfChar(Chr($43), 5) + Chr($49);
    DiceBottomRow := Chr($4a) + StringOfChar(Chr($43), 5) + Chr($4b);
    DiceLeft := Chr($42) + ' ';
    DiceRight := ' ' + Chr($42);
End;

(* Render each of the five dice *)
Procedure ShowDice;
Var
    i : Integer;
Begin
    For i := 1 To 5 Do Begin
        If Game.DiceToRoll[i] Then
            SetTextColor(1)
        Else
            SetTextColor(12);
        DrawDie(Game.DiceValues[i], (i-1)*8+3, 5);
        DrawChar((i-1)*8+6, 10, Chr(48+i));
    End;
End;

(* This procedure runs the game hands in a loop *)
Procedure RunGame;
Var
    ch : Char;
    i : Integer;
Begin
    For i := 1 To 5 Do Game.DiceToRoll[i] := True;
    Repeat
        If IsGameDone Then Begin
            ClearPrompts;
            DrawText(5, 18, 'game over. press a key. ');
            ch := GetKey;
            ResetGame;
            SetNextHand;
            CalcScore;
            DrawGameBoard;
        End;
        If Game.RollInHand < RollsPerHand Then Begin
            SetTextColor(7);
            If Game.RollInHand > 0 Then
                DrawText(5, 18, 'type number to hold dice');
            ShowRollDicePrompt;
            If Game.RollInHand > 0 Then
                DrawText(5, 21, 'press a letter to score hand');
        End Else
            ClearPrompts;
        ch := GetKey;
        Case ch Of
            ' ': Begin
                If Game.RollInHand < RollsPerHand Then Begin
                    RollDice;
                End;
            End;

            '1', '2', '3', '4', '5': Begin
                i := Ord(ch) - 48;
                Game.DiceToRoll[i] := Not Game.DiceToRoll[i];
                ShowDice;
            End;

            'a', 'A': Begin  // aces
                If Scores[Aces] = -1 Then
                    CalcFaceScore(1, Aces);
                SetNextHand;
            End;

            'b', 'B': Begin  // twos
                If Scores[Twos] = -1 Then
                    CalcFaceScore(2, Twos);
                SetNextHand;
            End;

            'c', 'C': Begin  // threes
                If Scores[Threes] = -1 Then
                    CalcFaceScore(3, Threes);
                SetNextHand;
            End;

            'd', 'D': Begin  // fours
                If Scores[Fours] = -1 Then
                    CalcFaceScore(4, Fours);
                SetNextHand;
            End;

            'e', 'E': Begin  // fives
                If Scores[Fives] = -1 Then
                    CalcFaceScore(5, Fives);
                SetNextHand;
            End;

            'f', 'F': Begin  // sixes
                If Scores[Sixes] = -1 Then
                    CalcFaceScore(6, Sixes);
                SetNextHand;
            End;

            'g', 'G': Begin  // three of a kind
                If Scores[ThreeOfAKind] = -1 Then Begin
                    Scores[ThreeOfAKind] := DoXOfAKind(3);
                    CalcScore;
                    DrawGameBoard;
                End;
                SetNextHand;
            End;

            'h', 'H': Begin  // four of a kind
                If Scores[FourOfAKind] = -1 Then Begin
                    Scores[FourOfAKind] := DoXOfAKind(4);
                    CalcScore;
                    DrawGameBoard;
                End;
                SetNextHand;
            End;

            'i', 'I': Begin  // full house
                If Scores[FullHouse] = -1 Then Begin
                    DoFullHouse;
                    CalcScore;
                    DrawGameBoard;
                End;
                SetNextHand;
            End;

            'j', 'J': Begin  // small straight
                If Scores[SmStraight] = -1 Then Begin
                    DoSmStraight;
                    CalcScore;
                    DrawGameBoard;
                End;
                SetNextHand;
            End;

            'k', 'K': Begin  // large straight
                If Scores[LgStraight] = -1 Then Begin
                    DoLgStraight;
                    CalcScore;
                    DrawGameBoard;
                End;
                SetNextHand;
            End;

            'l', 'L': Begin  // five of a kind
                DoFiveDice;
                CalcScore;
                DrawGameBoard;
                SetNextHand;
            End;

            'm', 'M': Begin  // chance
                If Scores[Chance] = -1 Then Begin
                    Scores[Chance] := CalcDiceTotal;
                    CalcScore;
                    DrawGameBoard;
                End;
                SetNextHand;
            End;
        End;
    Until False;
End;

(* Main Procedure *)
Begin
    ResetGame;

    ClearScreen;
    SetUpperCase;
    SetBackgroundColor(0);
    SetBorderColor(0);

    SetUpDice;

    DrawGameBoard;
    DrawInstructions;
    RunGame;
End.
