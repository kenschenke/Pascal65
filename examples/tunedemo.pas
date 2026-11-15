(*
 * Ken Schenke (kenschenke@gmail.com)
 *
 * A three-voice tune using the Sound library's sequencer
 *
 * Copyright (c) 2026
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Program TuneDemo;

// Plays a short tune on three voices with PlaySequence. The raster
// interrupt plays the sequences, so the program goes on printing the
// melody's notes and reading keys while the tune plays.
//
// An array's initial values must be literals, so the sequences are
// numbers. A note (0-95, octave * 12 + note) is followed by its length
// in ticks. The commands are 96 SeqRest, 97 SeqWave, 98 SeqEnvelope,
// 99 SeqTempo, 100 SeqPulse, 101 SeqLoop and 102 SeqEnd. A tick here is
// 3 frames, a sixteenth note, so 4 is a quarter note.

Uses Sound;

Const
    MelodyVoice = 1;
    BassVoice = 2;
    ChordVoice = 3;
    VicCtrl1 = $D011;   // Bit 7 is bit 8 of the raster line

Var
    // A pulse wave at half width (8 * 256), quick decay to a sustain
    // of 10. Eight bars of 16 ticks, then it loops.
    melody : Array[1..77] Of Byte = (
        99, 3, 97, 64, 100, 0, 8, 98, 9, 164,
        52, 4, 55, 4, 60, 4, 55, 4,             // E4 G4 C5 G4
        57, 4, 60, 4, 57, 2, 55, 2, 53, 4,      // A4 C5 A4 G4 F4
        50, 4, 55, 4, 59, 4, 62, 4,             // D4 G4 B4 D5
        60, 8, 96, 4, 55, 4,                    // C5, rest, G4
        57, 4, 60, 4, 64, 4, 60, 4,             // A4 C5 E5 C5
        53, 4, 57, 4, 60, 2, 57, 2, 53, 4,      // F4 A4 C5 A4 F4
        55, 2, 57, 2, 59, 2, 62, 2, 59, 4, 55, 4, // G4 A4 B4 D5 B4 G4
        60, 12, 96, 4,                          // C5, rest
        101);
    // A triangle wave, root and fifth on each beat
    bass : Array[1..66] Of Byte = (
        99, 3, 97, 16, 98, 6, 132,
        36, 4, 43, 4, 36, 4, 43, 4,             // C3 G3
        29, 4, 36, 4, 29, 4, 36, 4,             // F2 C3
        31, 4, 38, 4, 31, 4, 38, 4,             // G2 D3
        36, 4, 43, 4, 36, 8,                    // C3 G3 C3
        33, 4, 40, 4, 33, 4, 40, 4,             // A2 E3
        29, 4, 36, 4, 29, 4, 36, 4,             // F2 C3
        31, 4, 38, 4, 31, 4, 38, 4,             // G2 D3
        36, 8, 24, 8,                           // C3 C2
        101);
    // A soft sawtooth, the chord's notes a beat each
    chords : Array[1..72] Of Byte = (
        99, 3, 97, 32, 98, 4, 70,
        48, 4, 52, 4, 55, 4, 52, 4,             // C
        45, 4, 48, 4, 53, 4, 48, 4,             // F
        47, 4, 50, 4, 55, 4, 50, 4,             // G
        48, 4, 52, 4, 55, 4, 52, 4,             // C
        45, 4, 48, 4, 52, 4, 48, 4,             // A minor
        45, 4, 48, 4, 53, 4, 48, 4,             // F
        47, 4, 50, 4, 55, 4, 50, 4,             // G
        48, 4, 52, 4, 55, 4, 48, 4,             // C
        101);
    // Played once, when Q is pressed: a falling C major chord
    ending : Array[1..11] Of Byte = (99, 3, 67, 3, 64, 3, 60, 3, 48, 16, 102);
    noteNames : Array[0..11] Of String = ('C', 'C#', 'D', 'D#', 'E', 'F',
        'F#', 'G', 'G#', 'A', 'A#', 'B');
    ch : Char;
    n : Byte;
    playing, ended : Boolean;
    lastFreq, freq : Word;

// Waits for the raster to go back to the top of the screen, so the three
// sequences start between two interrupts and stay together
Procedure WaitFrame;
Begin
    While (Peek(VicCtrl1) & 128) = 0 Do Begin End;
    While (Peek(VicCtrl1) & 128) <> 0 Do Begin End;
End;

Procedure StartTune;
Begin
    WaitFrame;
    PlaySequence(MelodyVoice, @melody[1]);
    PlaySequence(BassVoice, @bass[1]);
    PlaySequence(ChordVoice, @chords[1]);
    playing := True;
End;

// Called from the raster interrupt when a voice's sequence ends. It only
// sets a variable, which the main program reads.
Procedure SequenceDone(voice : Byte);
Begin
    If voice = MelodyVoice Then ended := True;
End;

// Prints the name of the melody's note when it changes
Procedure ShowNote;
Var
    n : Byte;
Begin
    freq := GetFrequency(MelodyVoice);
    If freq <> lastFreq Then Begin
        lastFreq := freq;
        For n := 0 To 95 Do
            If NoteFreq(n) = freq Then
                Write(noteNames[n Mod 12], n Div 12, ' ');
    End;
End;

Begin
    Writeln('Tune demo');
    Writeln;
    Writeln('  Space  Stop / play');
    Writeln('  Q      Quit');
    Writeln;

    SetVolume(1, 15);
    SetSoundDoneCallback(@SequenceDone);
    lastFreq := 0;
    StartTune;

    Repeat
        ch := GetKeyNoWait;
        If ch = ' ' Then Begin
            If playing Then Begin
                StopAll;
                playing := False;
            End Else StartTune;
        End;
        If playing Then ShowNote;
    Until (ch = 'q') Or (ch = 'Q');

    // Play the ending on the melody's voice and wait for the callback
    StopAll;
    ended := False;
    PlaySequence(MelodyVoice, @ending[1]);
    While Not ended Do ShowNote;
    Writeln;
    // Let the last note's release play out
    For n := 1 To 25 Do WaitFrame;
End.
