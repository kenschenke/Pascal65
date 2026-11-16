(*
 * Ken Schenke (kenschenke@gmail.com)
 *
 * Hangman: guess the word one letter at a time
 *
 * Copyright (c) 2026
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Program Hangman;
(* $StaticRuntime *)

Const
    // The word list grows by this many elements at a time
    ChunkSize = 64;
    MinWordLen = 3;
    MaxWordLen = 12;
    // Wrong guesses that lose a round: head, body, two arms, two legs
    MaxMisses = 6;

Type
    GuessResult = (GuessCorrect, GuessWrong, GuessRepeat, GuessIgnored);

Var
    Words : Array Of String;
    NumWords : Integer;

    // The round state
    Secret : String;
    // Letters guessed so far, right or wrong (there are no sets)
    Guessed : Array['A'..'Z'] Of Boolean;
    // Letters of Secret not yet revealed, counting repeats
    LettersLeft : Integer;
    Misses : Integer;

// Returns a random number from 0 to 65535, from two reads of the
// MEGA65's hardware random number generator.
Function RandomWord : Word;
Var
    hi : Word;
Begin
    hi := Word(Peek($d7ef));
    RandomWord := (hi << 8) ! Word(Peek($d7ef));
End;

// Returns True if s is a usable word: MinWordLen to MaxWordLen
// letters and nothing else. s is already upper case.
Function IsUsableWord(s : String) : Boolean;
Var
    i, len : Integer;
    ok : Boolean;
Begin
    len := Length(s);
    ok := (len >= MinWordLen) And (len <= MaxWordLen);
    i := 1;
    While ok And (i <= len) Do Begin
        If (s[i] < 'A') Or (s[i] > 'Z') Then ok := False;
        Inc(i);
    End;
    IsUsableWord := ok;
End;

// Reads the "words" file into Words. The array grows in chunks of
// ChunkSize, since SetLength copies the whole array each time, and
// is trimmed to NumWords at the end. Lines that aren't usable words
// are skipped. Returns False, after printing why, if the file can't
// be read or holds no usable words.
Function LoadWords : Boolean;
Var
    f : Text;
    line : String;
    err : Word;
    readFailed : Boolean;
Begin
    LoadWords := False;
    NumWords := 0;
    readFailed := False;

    Assign(f, 'words');
    Reset(f);
    err := IOResult;
    If err <> 0 Then
        Writeln('Cannot open the words file (error ', err, ')')
    Else Begin
        While (Not readFailed) And (Not Eof(f)) Do Begin
            Readln(f, line);
            err := IOResult;
            If err <> 0 Then Begin
                Writeln('Cannot read the words file (error ', err, ')');
                readFailed := True;
            End Else Begin
                line := Trim(UpCase(line));
                If IsUsableWord(line) Then Begin
                    If NumWords = Length(Words) Then
                        SetLength(Words, NumWords + ChunkSize);
                    Words[NumWords] := line;
                    Inc(NumWords);
                End;
            End;
        End;
        Close(f);

        SetLength(Words, NumWords);
        If readFailed Then
            NumWords := 0
        Else If NumWords = 0 Then
            Writeln('The words file has no usable words')
        Else
            LoadWords := True;
    End;
End;

// Shuffles Words (Fisher-Yates), so taking them in order never
// repeats a word.
Procedure ShuffleWords;
Var
    i, j : Integer;
    tmp : String;
Begin
    For i := NumWords - 1 DownTo 1 Do Begin
        j := Integer(RandomWord Mod Word(i + 1));
        tmp := Words[i];
        Words[i] := Words[j];
        Words[j] := tmp;
    End;
End;

// Starts a round with word w: nothing guessed, no misses.
Procedure StartRound(w : String);
Var
    c : Char;
Begin
    Secret := w;
    For c := 'A' To 'Z' Do Guessed[c] := False;
    LettersLeft := Length(Secret);
    Misses := 0;
End;

// Returns ch in upper case if it is a letter, or Chr(0) if it isn't.
// Unshifted keys give lower case and shifted keys upper case.
Function KeyToLetter(ch : Char) : Char;
Begin
    If (ch >= 'a') And (ch <= 'z') Then
        KeyToLetter := Chr(Ord(ch) - Ord('a') + Ord('A'))
    Else If (ch >= 'A') And (ch <= 'Z') Then
        KeyToLetter := ch
    Else
        KeyToLetter := Chr(0);
End;

// Plays the letter on key ch. A letter guessed before costs nothing,
// and a key that isn't a letter is ignored.
Function Guess(ch : Char) : GuessResult;
Var
    letter : Char;
    i, found : Integer;
Begin
    letter := KeyToLetter(ch);
    If letter = Chr(0) Then
        Guess := GuessIgnored
    Else If Guessed[letter] Then
        Guess := GuessRepeat
    Else Begin
        Guessed[letter] := True;
        found := 0;
        For i := 1 To Length(Secret) Do
            If Secret[i] = letter Then Inc(found);
        If found > 0 Then Begin
            LettersLeft := LettersLeft - found;
            Guess := GuessCorrect;
        End Else Begin
            Inc(Misses);
            Guess := GuessWrong;
        End;
    End;
End;

Function RoundWon : Boolean;
Begin
    RoundWon := LettersLeft = 0;
End;

Function RoundLost : Boolean;
Begin
    RoundLost := Misses >= MaxMisses;
End;

// Prints the word with an underscore for each letter not yet guessed.
Procedure ShowWord;
Var
    i : Integer;
Begin
    Write('Word:   ');
    For i := 1 To Length(Secret) Do
        If Guessed[Secret[i]] Then
            Write(' ', Secret[i])
        Else
            Write(' _');
    Writeln;
End;

// Prints the letters guessed so far, in alphabetical order.
Procedure ShowGuessed;
Var
    c : Char;
Begin
    Write('Guessed:');
    For c := 'A' To 'Z' Do
        If Guessed[c] Then Write(' ', c);
    Writeln;
End;

Procedure ShowState;
Begin
    Writeln;
    ShowWord;
    ShowGuessed;
    Writeln('Misses:  ', Misses, ' of ', MaxMisses);
End;

// Plays one round with word w, until it is won or lost.
Procedure PlayRound(w : String);
Var
    ch : Char;
    res : GuessResult;
Begin
    StartRound(w);
    ShowState;
    While (Not RoundWon) And (Not RoundLost) Do Begin
        Write('Press a letter: ');
        Repeat
            ch := GetKey;
            res := Guess(ch);
        Until res <> GuessIgnored;
        Writeln(KeyToLetter(ch));
        If res = GuessCorrect Then
            Writeln('Yes!')
        Else If res = GuessWrong Then
            Writeln('No.')
        Else
            Writeln('Already guessed.');
        If res <> GuessRepeat Then ShowState;
    End;

    Writeln;
    If RoundWon Then
        Writeln('You win! The word was ', Secret)
    Else
        Writeln('You lose. The word was ', Secret);
End;

Begin
    Writeln('Loading words...');
    If LoadWords Then Begin
        ShuffleWords;
        PlayRound(Words[0]);
    End;
End.
