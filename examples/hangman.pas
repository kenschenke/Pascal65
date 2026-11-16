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

Uses Screen, Sound;

// Sounds play on SID 1 (the right channel) and the same voice of SID 3
// (the left), so they come from both speakers. The music's melody and
// bass are on voices 1 and 2, and the effects on voice 3. The helpers
// below make each call on both voices.
//
// An array's initial values must be literals, so the sequences are
// numbers. A note (0-95, octave * 12 + note) is followed by its length
// in ticks. The commands are 96 SeqRest, 97 SeqWave, 98 SeqEnvelope,
// 99 SeqTempo, 100 SeqPulse, 101 SeqLoop and 102 SeqEnd. A tick here is
// 3 frames, a sixteenth note, so 4 is a quarter note.

Const
    // The word list grows by this many elements at a time
    ChunkSize = 64;
    MinWordLen = 3;
    MaxWordLen = 12;
    // Wrong guesses that lose a round: head, body, two arms, two legs
    MaxMisses = 6;

    // Screen positions (1-based)
    TitleCol = 34;
    TitleRow = 2;
    LabelCol = 26;
    ValueCol = 35;
    WordRow = 5;
    GuessedRow = 7;
    MissesRow = 9;
    ScoreCol = 3;
    PromptRow = 14;
    MessageRow = 16;
    MusicCol = 67;
    MusicRow = 25;
    // Spaces that clear the prompt or message, to the right edge
    LineWidth = 54;

    // The gallows: the pole, the beam over to the rope, and the base
    PoleCol = 6;
    RopeCol = 12;
    BeamRow = 5;
    BaseRow = 12;
    BaseLeft = 2;
    BaseRight = 12;

    // The hanged man, under the rope
    HeadRow = 7;
    ArmsRow = 8;
    LegsRow = 10;

    // Screen codes in the upper case character set
    ScBlank = $64;          // a line at the bottom of the cell
    ScHoriz = $40;
    ScVert = $5d;
    ScTopLeft = $70;
    ScTopRight = $6e;
    ScBase = $62;           // the lower half of the cell
    ScHead = $51;           // a ball
    ScSlash = $4e;
    ScBackslash = $4d;

    // Colors
    ColorTitle = 7;         // yellow
    ColorLabel = 15;        // light grey
    ColorGallows = 8;       // orange
    ColorMan = 1;           // white
    ColorHit = 13;          // light green
    ColorMiss = 10;         // light red
    ColorBlank = 12;        // grey
    ColorPrompt = 7;        // yellow
    ColorScore = 3;         // cyan

    // Voices on SID 1 (right) and the same voices on SID 3 (left)
    MelodyVoice = 1;
    BassVoice = 2;
    FxVoice = 3;
    MelodyLeft = 7;
    BassLeft = 8;
    FxLeft = 9;
    VicCtrl1 = $D011;       // Bit 7 is bit 8 of the raster line
    // The lost round's "wah": a swing of 1.5% each way, 3 frames a swing
    LoseVibratoDepth = 15;
    LoseVibratoFrames = 3;

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

    // Rounds won and lost this session
    Won, Lost : Integer;
    // A key pressed to go on, whatever it is
    AnyKey : Char;

    // True while the tune plays during a round. The 1 key changes it.
    MusicOn : Boolean;
    // True while the coin's second note waits for the first to end
    CoinWaiting : Boolean;

    // The round's tune, in A minor. A soft pulse wave, eight bars of
    // 16 ticks, then it loops.
    TuneMelody : Array[1..75] Of Byte = (
        99, 3, 97, 64, 100, 0, 8, 98, 8, 86,
        57, 4, 60, 4, 64, 4, 60, 4,             // A4 C5 E5 C5
        62, 4, 60, 2, 59, 2, 57, 8,             // D5 C5 B4 A4
        55, 4, 59, 4, 62, 4, 59, 4,             // G4 B4 D5 B4
        60, 4, 59, 2, 57, 2, 55, 8,             // C5 B4 A4 G4
        53, 4, 57, 4, 60, 4, 57, 4,             // F4 A4 C5 A4
        52, 4, 55, 4, 59, 4, 64, 4,             // E4 G4 B4 E5
        62, 2, 60, 2, 59, 2, 60, 2, 59, 4, 56, 4, // D5 C5 B4 C5 B4 G#4
        57, 12, 96, 4,                          // A4, rest
        101);
    // A triangle wave, a root and a fifth in each bar
    TuneBass : Array[1..40] Of Byte = (
        99, 3, 97, 16, 98, 6, 132,
        33, 8, 40, 8,                           // A2 E3
        38, 8, 33, 8,                           // D3 A2
        31, 8, 38, 8,                           // G2 D3
        36, 8, 31, 8,                           // C3 G2
        29, 8, 36, 8,                           // F2 C3
        28, 8, 35, 8,                           // E2 B2
        28, 8, 32, 8,                           // E2 G#2
        33, 12, 96, 4,                          // A2, rest
        101);

    // A round won: a rising fanfare on a square wave, over C major
    WinMelody : Array[1..23] Of Byte = (
        99, 3, 97, 64, 100, 0, 8, 98, 9, 168,
        60, 2, 64, 2, 67, 2, 72, 6, 67, 2, 72, 8, // C5 E5 G5 C6 G5 C6
        102);
    WinBass : Array[1..14] Of Byte = (
        99, 3, 97, 16, 98, 9, 136,
        36, 6, 43, 6, 48, 10,                   // C3 G3 C4
        102);

    // A round lost: a sawtooth falling a semitone at a time, with a
    // vibrato (LoseVibrato) that makes it "wah", then a low note
    LoseMelody : Array[1..16] Of Byte = (
        99, 3, 97, 32, 98, 32, 200,
        55, 8, 54, 8, 53, 8, 52, 20,            // G4 F#4 F4 E4
        102);
    LoseBass : Array[1..12] Of Byte = (
        99, 3, 97, 32, 98, 0, 250,
        96, 24, 28, 20,                         // rest, E2
        102);

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

// Returns True if letter is in Secret.
Function InSecret(letter : Char) : Boolean;
Var
    i : Integer;
    found : Boolean;
Begin
    found := False;
    For i := 1 To Length(Secret) Do
        If Secret[i] = letter Then found := True;
    InSecret := found;
End;

// Draws an upper case letter. The words are upper case PETSCII, which
// the upper case character set shows as graphics, so the letter is
// drawn by its screen code: 1 for A to 26 for Z.
Procedure DrawLetter(col, row : Byte; letter : Char);
Begin
    DrawCharRaw(col, row, Chr(Ord(letter) - Ord('A') + 1));
End;

// Clears the prompt or message line from LabelCol to the right edge.
Procedure ClearLine(row : Byte);
Begin
    DrawText(LabelCol, row, StringOfChar(' ', LineWidth));
End;

// Shows msg on the prompt line, in color.
Procedure ShowPrompt(msg : String; color : Byte);
Begin
    ClearLine(PromptRow);
    SetTextColor(color);
    DrawText(LabelCol, PromptRow, msg);
End;

// Shows msg and then letter on the message line, in color.
Procedure ShowMessage(msg : String; color : Byte; letter : Char);
Begin
    ClearLine(MessageRow);
    SetTextColor(color);
    DrawText(LabelCol, MessageRow, msg);
    DrawLetter(LabelCol + Length(msg), MessageRow, letter);
End;

// Draws the gallows with nobody on it.
Procedure DrawGallows;
Var
    col, row : Byte;
Begin
    SetTextColor(ColorGallows);
    DrawCharRaw(PoleCol, BeamRow, Chr(ScTopLeft));
    For col := PoleCol + 1 To RopeCol - 1 Do
        DrawCharRaw(col, BeamRow, Chr(ScHoriz));
    DrawCharRaw(RopeCol, BeamRow, Chr(ScTopRight));
    DrawCharRaw(RopeCol, BeamRow + 1, Chr(ScVert));
    For row := BeamRow + 1 To BaseRow - 1 Do
        DrawCharRaw(PoleCol, row, Chr(ScVert));
    For col := BaseLeft To BaseRight Do
        DrawCharRaw(col, BaseRow, Chr(ScBase));
End;

// Draws part n of the hanged man, 1 to MaxMisses: the head, body,
// left arm, right arm, left leg and right leg.
Procedure DrawPart(n : Integer);
Begin
    SetTextColor(ColorMan);
    If n = 1 Then
        DrawCharRaw(RopeCol, HeadRow, Chr(ScHead))
    Else If n = 2 Then Begin
        DrawCharRaw(RopeCol, ArmsRow, Chr(ScVert));
        DrawCharRaw(RopeCol, ArmsRow + 1, Chr(ScVert));
    End Else If n = 3 Then
        DrawCharRaw(RopeCol - 1, ArmsRow, Chr(ScSlash))
    Else If n = 4 Then
        DrawCharRaw(RopeCol + 1, ArmsRow, Chr(ScBackslash))
    Else If n = 5 Then
        DrawCharRaw(RopeCol - 1, LegsRow, Chr(ScSlash))
    Else If n = 6 Then
        DrawCharRaw(RopeCol + 1, LegsRow, Chr(ScBackslash));
End;

// Draws the word, a line for each letter not yet guessed. With reveal
// True (a lost round), the missing letters are shown in ColorMiss.
Procedure DrawWord(reveal : Boolean);
Var
    i : Integer;
    col : Byte;
Begin
    col := ValueCol;
    For i := 1 To Length(Secret) Do Begin
        If Guessed[Secret[i]] Then Begin
            SetTextColor(ColorHit);
            DrawLetter(col, WordRow, Secret[i]);
        End Else If reveal Then Begin
            SetTextColor(ColorMiss);
            DrawLetter(col, WordRow, Secret[i]);
        End Else Begin
            SetTextColor(ColorBlank);
            DrawCharRaw(col, WordRow, Chr(ScBlank));
        End;
        col := col + 2;
    End;
End;

// Draws the letters guessed so far in alphabetical order, the ones in
// the word in ColorHit and the misses in ColorMiss. A round ends after
// MaxMisses misses, and the word has at most MaxWordLen letters, so the
// list always fits on the line.
Procedure DrawGuessed;
Var
    c : Char;
    col : Byte;
Begin
    col := ValueCol;
    For c := 'A' To 'Z' Do
        If Guessed[c] Then Begin
            If InSecret(c) Then
                SetTextColor(ColorHit)
            Else
                SetTextColor(ColorMiss);
            DrawLetter(col, GuessedRow, c);
            col := col + 2;
        End;
End;

Procedure DrawMisses;
Begin
    If Misses > 0 Then
        SetTextColor(ColorMiss)
    Else
        SetTextColor(ColorLabel);
    DrawText(ValueCol, MissesRow,
        WriteStr(Misses) + ' of ' + WriteStr(MaxMisses));
End;

Procedure DrawScore;
Begin
    SetTextColor(ColorScore);
    DrawText(ScoreCol, PromptRow,
        'won: ' + WriteStr(Won) + '   lost: ' + WriteStr(Lost));
End;

// Clears the screen and draws everything for a new round.
Procedure DrawBoard;
Begin
    ClearScreen;
    SetTextColor(ColorTitle);
    DrawText(TitleCol, TitleRow, 'h a n g m a n');
    SetTextColor(ColorLabel);
    DrawText(LabelCol, WordRow, 'word:');
    DrawText(LabelCol, GuessedRow, 'guessed:');
    DrawText(LabelCol, MissesRow, 'misses:');
    DrawGallows;
    DrawWord(False);
    DrawMisses;
    DrawScore;
End;

// Waits for the raster to go back to the top of the screen, so sounds
// started next all start between two interrupts and stay together.
Procedure WaitFrame;
Begin
    While (Peek(VicCtrl1) & 128) = 0 Do Begin End;
    While (Peek(VicCtrl1) & 128) <> 0 Do Begin End;
End;

// Sets the waveform, pulse width and envelope of both effects voices.
// Each effect sets them up first, since they share the voices.
Procedure SetUpSfx(wave, width : Word; attack, decay, sustain,
    release : Byte);
Begin
    SetWaveform(FxVoice, wave);
    SetPulseWidth(FxVoice, width);
    SetEnvelope(FxVoice, attack, decay, sustain, release);
    SetWaveform(FxLeft, wave);
    SetPulseWidth(FxLeft, width);
    SetEnvelope(FxLeft, attack, decay, sustain, release);
End;

// Plays a note on both effects voices.
Procedure Sfx(note : Word; frames : Byte);
Begin
    PlayNote(FxVoice, note, frames);
    PlayNote(FxLeft, note, frames);
End;

// Starts two sequences together, mel on the melody voices and bas on
// the bass voices. The sequences set their own waveforms and envelopes.
Procedure PlayPairs(mel, bas : ^Byte);
Begin
    WaitFrame;
    PlaySequence(MelodyVoice, mel);
    PlaySequence(MelodyLeft, mel);
    PlaySequence(BassVoice, bas);
    PlaySequence(BassLeft, bas);
End;

// Stops the music voices, with their effects.
Procedure StopTune;
Begin
    StopVoice(MelodyVoice);
    StopVoice(MelodyLeft);
    StopVoice(BassVoice);
    StopVoice(BassLeft);
End;

// Starts the round's tune from the top, if the music is on. Stopping
// the voices first ends the lost round's vibrato.
Procedure StartTune;
Begin
    StopTune;
    If MusicOn Then PlayPairs(@TuneMelody[1], @TuneBass[1]);
End;

// A correct letter: two quick rising square notes. The second starts
// from CheckSound when the first ends, so the game doesn't wait.
Procedure SfxCorrect;
Begin
    SetUpSfx(WavePulse, 2048, 0, 0, 15, 7);
    Sfx(5 * 12 + NoteB, 4);
    CoinWaiting := True;
End;

// A wrong letter: a low sawtooth that falls, a thud.
Procedure SfxWrong;
Begin
    CoinWaiting := False;
    SetUpSfx(WaveSaw, 0, 0, 8, 0, 8);
    PlayFreq(FxVoice, 2500, 10);
    PlayFreq(FxLeft, 2500, 10);
    Sweep(FxVoice, 2500, 500, 15);
    Sweep(FxLeft, 2500, 500, 15);
End;

// A letter guessed before: a short, quiet triangle blip.
Procedure SfxRepeat;
Begin
    CoinWaiting := False;
    SetUpSfx(WaveTriangle, 0, 0, 0, 6, 3);
    Sfx(6 * 12 + NoteC, 3);
End;

// Plays the coin's second note once both voices have ended the first.
Procedure CheckSound;
Begin
    If CoinWaiting And (Not IsPlaying(FxVoice))
        And (Not IsPlaying(FxLeft)) Then Begin
        Sfx(6 * 12 + NoteE, 12);
        CoinWaiting := False;
    End;
End;

// The jingles play on the music voices, with the music on or off.
Procedure JingleWon;
Begin
    StopTune;
    PlayPairs(@WinMelody[1], @WinBass[1]);
End;

// The vibrato is set before the sequence starts. It stays on from
// note to note, and each note starts it over.
Procedure JingleLost;
Begin
    StopTune;
    Vibrato(MelodyVoice, LoseVibratoDepth, LoseVibratoFrames);
    Vibrato(MelodyLeft, LoseVibratoDepth, LoseVibratoFrames);
    PlayPairs(@LoseMelody[1], @LoseBass[1]);
End;

// Waits for a key. While the coin's second note is pending the key is
// read without waiting, so CheckSound can start the note.
Function WaitKey : Char;
Var
    ch : Char;
Begin
    ch := Chr(0);
    While CoinWaiting And (ch = Chr(0)) Do Begin
        ch := GetKeyNoWait;
        CheckSound;
    End;
    If ch = Chr(0) Then ch := GetKey;
    WaitKey := ch;
End;

// Shows what the 1 key does on the bottom line.
Procedure DrawMusic;
Begin
    SetTextColor(ColorLabel);
    If MusicOn Then
        DrawText(MusicCol, MusicRow, '1: music off')
    Else
        DrawText(MusicCol, MusicRow, '1: music on ');
End;

// The 1 key during a round turns the music off or on.
Procedure ToggleMusic;
Begin
    MusicOn := Not MusicOn;
    If MusicOn Then StartTune Else StopTune;
    DrawMusic;
End;

// Plays one round with word w, until it is won or lost.
Procedure PlayRound(w : String);
Var
    ch, letter : Char;
    res : GuessResult;
Begin
    StartRound(w);
    DrawBoard;
    DrawMusic;
    StartTune;
    While (Not RoundWon) And (Not RoundLost) Do Begin
        ShowPrompt('press a letter', ColorPrompt);
        Repeat
            ch := WaitKey;
            If ch = '1' Then ToggleMusic;
            res := Guess(ch);
        Until res <> GuessIgnored;
        letter := KeyToLetter(ch);
        If res = GuessCorrect Then Begin
            SfxCorrect;
            ShowMessage('yes! ', ColorHit, letter);
            DrawWord(False);
            DrawGuessed;
        End Else If res = GuessWrong Then Begin
            SfxWrong;
            ShowMessage('no ', ColorMiss, letter);
            DrawPart(Misses);
            DrawGuessed;
            DrawMisses;
        End Else Begin
            SfxRepeat;
            ShowMessage('already guessed ', ColorBlank, letter);
        End;
    End;

    ClearLine(MessageRow);
    If RoundWon Then Begin
        Inc(Won);
        JingleWon;
        ShowPrompt('you win!', ColorHit);
    End Else Begin
        Inc(Lost);
        JingleLost;
        DrawWord(True);
        ShowPrompt('you lose! the word was ' + LowerCase(Secret), ColorMiss);
    End;
    DrawScore;
End;


Begin
    Writeln('Loading words...');
    If LoadWords Then Begin
        ShuffleWords;
        SetScreenSize(80, 25);
        SetUpperCase;
        SetBackgroundColor(0);
        SetBorderColor(0);
        Won := 0;
        Lost := 0;
        MusicOn := True;
        CoinWaiting := False;
        PlayRound(Words[0]);
        SetTextColor(ColorLabel);
        DrawText(LabelCol, MessageRow, 'press a key');
        AnyKey := WaitKey;
        ClearScreen;
    End;
End.
