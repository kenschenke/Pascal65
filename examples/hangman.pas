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
    // How many words the loader test prints
    NumShown = 8;

Var
    Words : Array Of String;
    NumWords : Integer;
    i : Integer;

// Returns a random number from 0 to 65535, from two reads of the
// MEGA65's hardware random number generator.
Function RandomWord : Word;
Var
    hi : Word;
Begin
    hi := Word(Peek($d7ef));
    RandomWord := (hi << 8) ! Word(Peek($d7ef));
End;

// Returns a random index into Words.
Function RandomIndex : Integer;
Begin
    RandomIndex := Integer(RandomWord Mod Word(NumWords));
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

// Prints the first NumShown words, or all of them if there are fewer.
Procedure ShowFirstWords;
Var
    i : Integer;
Begin
    i := 0;
    While (i < NumShown) And (i < NumWords) Do Begin
        Write(' ', Words[i]);
        Inc(i);
    End;
    Writeln;
End;

Begin
    Writeln('Loading words...');
    If LoadWords Then Begin
        Writeln('Loaded ', NumWords, ' words');

        Write('Random picks:');
        For i := 1 To NumShown Do Write(' ', Words[RandomIndex]);
        Writeln;

        ShuffleWords;
        Writeln('Shuffled, ', Length(Words), ' words. First ', NumShown, ':');
        ShowFirstWords;
    End;
End.
