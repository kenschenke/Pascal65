Program SoundSeq;

// Tests the Sound library's sequencer (PlaySequence) and done callback
// (SetSoundDoneCallback, ClearSoundDoneCallback). soundtest and soundfx
// have the other tests.
//
// The library moves sequences on in the raster interrupt at line 210.
// WaitFrames counts the frames by watching the raster pass line 256 and
// go back to 0. Right after WaitFrames the raster is near line 0, so a
// sequence started then sees exactly n interrupts in the next n frames.
// Each timed test starts right after one: a few calls can take the
// raster past line 210.
//
// The sequences are written as numbers: an array's initial values must
// be literals. 96 is SeqRest, 97 SeqWave, 98 SeqEnvelope, 99 SeqTempo,
// 100 SeqPulse, 101 SeqLoop and 102 SeqEnd.

Uses Sound;

Const
    VicCtrl1 = $D011;   // Bit 7 is bit 8 of the raster line

Var
    anyErrors : Boolean;
    errList : String;
    i, chain : Byte;
    n : Word;
    f50, f52, f57 : Word;
    doneCounts : Array[1..12] Of Byte;
    nilPtr : ^Byte;
    // 57 for 3 ticks, then 60 for 2
    twoNotes : Array[1..5] Of Byte = (57, 3, 60, 2, 102);
    // A tempo of 3 frames a tick: 6 frames
    tempo : Array[1..5] Of Byte = (99, 3, 50, 2, 102);
    // A note, a rest of 2 and a note
    rest : Array[1..7] Of Byte = (50, 1, 96, 2, 52, 1, 102);
    // Loops until it's stopped
    looping : Array[1..5] Of Byte = (50, 1, 52, 1, 101);
    // Loops with no note between: ends at once
    noNote : Array[1..3] Of Byte = (97, 16, 101);
    // A byte past SeqEnd ends it
    badByte : Array[1..3] Of Byte = (50, 1, 200);
    // A pulse width of 18 * 256 + 52, in 12 bits 564, then a note
    pulse : Array[1..6] Of Byte = (100, 52, 18, 50, 1, 102);
    // A waveform and an envelope, then a note
    waveEnv : Array[1..8] Of Byte = (97, 64, 98, 9, 0, 55, 1, 102);
    // A length of 0 and a tempo of 0 are taken as 1
    zeros : Array[1..7] Of Byte = (99, 0, 50, 0, 52, 1, 102);

Procedure Error(num : Integer);
Begin
    Writeln('SoundSeq (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
End;

// Fails test num if actual isn't expected
Procedure Expect(actual, expected : Word; num : Integer);
Begin
    If actual <> expected Then Error(num);
End;

// Fails test num if IsPlaying(voice) isn't playing
Procedure ExpectPlaying(voice : Byte; playing : Boolean; num : Integer);
Begin
    If IsPlaying(voice) <> playing Then Error(num);
End;

Procedure WaitFrames(count : Byte);
Var
    n : Byte;
Begin
    For n := 1 To count Do Begin
        While (Peek(VicCtrl1) & 128) = 0 Do Begin End;
        While (Peek(VicCtrl1) & 128) <> 0 Do Begin End;
    End;
End;

// The done callback. It runs in the raster interrupt. For voice 7 it
// plays another note while chain is over 0.
Procedure SoundDone(voice : Byte);
Begin
    doneCounts[voice] := doneCounts[voice] + 1;
    If (voice = 7) And (chain > 0) Then Begin
        chain := chain - 1;
        PlayNote(7, 50, 1);
    End;
End;

Procedure ClearCounts;
Var
    v : Byte;
Begin
    For v := 1 To 12 Do doneCounts[v] := 0;
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
    If Length(acc) < 150 Then acc := acc + 'soundseq:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    Writeln('Running sound sequence tests');

    anyErrors := false;
    errList := '';
    chain := 0;
    ClearCounts;
    f50 := NoteFreq(50);
    f52 := NoteFreq(52);
    f57 := NoteFreq(57);

    // Give the voices a sound so the tests can be heard when run by hand
    SetVolume(1, 15);
    SetVolume(2, 15);
    SetVolume(3, 15);
    For i := 1 To 12 Do Begin
        SetWaveform(i, WaveTriangle);
        SetEnvelope(i, 0, 0, 15, 0);
    End;
    SetSoundDoneCallback(@SoundDone);

    // Bad voice numbers and a Nil sequence are ignored
    PlaySequence(0, @looping[1]);
    PlaySequence(13, @looping[1]);
    nilPtr := Nil;
    PlaySequence(1, nilPtr);
    ExpectPlaying(13, False, 100);
    ExpectPlaying(1, False, 101);

    // The first note starts at once and the next after its length
    WaitFrames(1);
    PlaySequence(1, @twoNotes[1]);
    ExpectPlaying(1, True, 110);
    Expect(GetFrequency(1), NoteFreq(57), 111);
    WaitFrames(2);
    Expect(GetFrequency(1), NoteFreq(57), 112);
    WaitFrames(1);
    Expect(GetFrequency(1), NoteFreq(60), 113);
    WaitFrames(1);
    ExpectPlaying(1, True, 114);
    Expect(doneCounts[1], 0, 115);
    WaitFrames(1);
    ExpectPlaying(1, False, 116);
    Expect(doneCounts[1], 1, 117);
    WaitFrames(3);
    Expect(doneCounts[1], 1, 118);

    // Ticks of 3 frames
    WaitFrames(1);
    PlaySequence(2, @tempo[1]);
    WaitFrames(5);
    ExpectPlaying(2, True, 120);
    WaitFrames(1);
    ExpectPlaying(2, False, 121);

    // A rest keeps the sequence playing and the frequency where it was
    WaitFrames(1);
    PlaySequence(3, @rest[1]);
    WaitFrames(1);
    ExpectPlaying(3, True, 130);
    Expect(GetFrequency(3), f50, 131);
    WaitFrames(1);
    Expect(GetFrequency(3), f50, 132);
    WaitFrames(1);
    Expect(GetFrequency(3), f52, 133);
    WaitFrames(1);
    ExpectPlaying(3, False, 134);
    Expect(doneCounts[3], 1, 135);

    // A loop plays until it's stopped. StopVoice doesn't call back.
    WaitFrames(1);
    PlaySequence(4, @looping[1]);
    WaitFrames(1);
    Expect(GetFrequency(4), f52, 140);
    WaitFrames(1);
    Expect(GetFrequency(4), f50, 141);
    WaitFrames(10);
    ExpectPlaying(4, True, 142);
    StopVoice(4);
    ExpectPlaying(4, False, 143);
    WaitFrames(2);
    Expect(doneCounts[4], 0, 144);

    // A loop with no note in it ends at once. The callback is called on
    // the next interrupt.
    WaitFrames(1);
    PlaySequence(5, @noNote[1]);
    ExpectPlaying(5, False, 150);
    WaitFrames(1);
    Expect(doneCounts[5], 1, 151);

    // A byte past SeqEnd ends the sequence
    WaitFrames(1);
    PlaySequence(6, @badByte[1]);
    WaitFrames(1);
    ExpectPlaying(6, False, 160);
    Expect(doneCounts[6], 1, 161);

    // SeqPulse sets 12 bits of the pulse width. SeqWave and SeqEnvelope
    // take their bytes.
    PlaySequence(8, @pulse[1]);
    Expect(GetPulseWidth(8), 564, 170);
    Expect(GetFrequency(8), f50, 171);
    PlaySequence(9, @waveEnv[1]);
    Expect(GetFrequency(9), NoteFreq(55), 172);

    // A length of 0 and a tempo of 0 are 1
    WaitFrames(1);
    PlaySequence(10, @zeros[1]);
    WaitFrames(1);
    Expect(GetFrequency(10), f52, 180);
    WaitFrames(1);
    ExpectPlaying(10, False, 181);

    // A note ends a sequence on its voice
    WaitFrames(1);
    PlaySequence(11, @looping[1]);
    PlayNote(11, 40, 2);
    WaitFrames(3);
    ExpectPlaying(11, False, 190);
    Expect(GetFrequency(11), NoteFreq(40), 191);
    Expect(doneCounts[11], 1, 192);

    // The callback is called once for each voice that ends, even in the
    // same frame
    ClearCounts;
    WaitFrames(1);
    For i := 1 To 6 Do PlayNote(i, 50, 1);
    StopVoice(6);
    WaitFrames(3);
    For i := 1 To 5 Do Expect(doneCounts[i], 1, 200);
    Expect(doneCounts[6], 0, 201);

    // The callback can play a note. Meanwhile the program's own calls
    // and arithmetic go on, and a sequence on another voice works out a
    // note's frequency each frame, so the interrupt mustn't change what
    // they use.
    ClearCounts;
    chain := 3;
    PlayNote(7, 50, 1);
    PlaySequence(12, @looping[1]);
    For n := 1 To 3000 Do Begin
        If NoteFreq(57) + n <> f57 + n Then Error(210);
        Expect(NoteFreq(57), f57, 211);
    End;
    StopVoice(12);
    WaitFrames(6);
    Expect(chain, 0, 212);
    Expect(doneCounts[7], 4, 213);
    ExpectPlaying(7, False, 214);

    // ClearSoundDoneCallback turns the callback off
    ClearSoundDoneCallback;
    ClearCounts;
    WaitFrames(1);
    PlayNote(1, 50, 1);
    WaitFrames(3);
    Expect(doneCounts[1], 0, 220);

    StopAll;

    If anyErrors Then ReportFailure;
End.
