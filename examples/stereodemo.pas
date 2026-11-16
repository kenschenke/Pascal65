(*
 * Ken Schenke (kenschenke@gmail.com)
 *
 * Stereo sound using the Sound library
 *
 * Copyright (c) 2026
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)

Program StereoDemo;

// Moves a sound between the right and left channels. SIDs 1 and 2 play
// on the right and SIDs 3 and 4 on the left, so voice 1 (on SID 1) is on
// the right and voice 7 (on SID 3) on the left.
//
// Bounce plays a note on one side, then the other. Pan plays the note on
// both voices at once and fades one SID's volume up as the other's goes
// down, so the sound glides across. The main loop waits a frame each time
// round and counts frames, so it goes on reading keys.

Uses Sound;

Const
    RightVoice = 1;     // On SID 1, the right channel
    LeftVoice = 7;      // On SID 3, the left channel
    RightSid = 1;
    LeftSid = 3;
    BounceFrames = 15;  // Frames from one bounce to the next
    PanFrames = 3;      // Frames each step of the pan's volume lasts
    VicCtrl1 = $D011;   // Bit 7 is bit 8 of the raster line

Var
    ch : Char;
    bouncing, panning, onRight, panToLeft : Boolean;
    rightVol, leftVol, frames : Byte;

// Waits for the raster to go back to the top of the screen
Procedure WaitFrame;
Begin
    While (Peek(VicCtrl1) & 128) = 0 Do Begin End;
    While (Peek(VicCtrl1) & 128) <> 0 Do Begin End;
End;

Procedure ShowMenu;
Begin
    Writeln('Stereo demo');
    Writeln;
    Writeln('  1  Bounce');
    Writeln('  2  Pan');
    Writeln('  0  Stop');
    Writeln('  Q  Quit');
    Writeln;
End;

// Both voices get the same sound, so only the side changes
Procedure SetUpVoices;
Begin
    SetWaveform(RightVoice, WavePulse);
    SetPulseWidth(RightVoice, 1536);
    SetEnvelope(RightVoice, 0, 6, 6, 8);
    SetWaveform(LeftVoice, WavePulse);
    SetPulseWidth(LeftVoice, 1536);
    SetEnvelope(LeftVoice, 0, 6, 6, 8);
End;

// Stops both voices and puts both volumes back
Procedure StopEverything;
Begin
    StopAll;
    bouncing := False;
    panning := False;
    SetVolume(RightSid, 15);
    SetVolume(LeftSid, 15);
End;

// Plays the bounce's next note, on the other side from the last one
Procedure Bounce;
Begin
    onRight := Not onRight;
    If onRight Then Begin
        Writeln('Right');
        PlayNote(RightVoice, 5 * 12 + NoteC, 6);
    End Else Begin
        Writeln('Left');
        PlayNote(LeftVoice, 5 * 12 + NoteC, 6);
    End;
    frames := BounceFrames;
End;

Procedure StartBounce;
Begin
    StopEverything;
    Writeln('Bounce');
    bouncing := True;
    onRight := False;
    frames := 0;            // The first note plays at once
End;

// Moves the pan one step: one SID's volume up and the other's down. At
// either end it turns round.
Procedure PanStep;
Begin
    If panToLeft Then Begin
        Dec(rightVol);
        Inc(leftVol);
        If rightVol = 0 Then Begin
            Writeln('Left');
            panToLeft := False;
        End;
    End Else Begin
        Inc(rightVol);
        Dec(leftVol);
        If leftVol = 0 Then Begin
            Writeln('Right');
            panToLeft := True;
        End;
    End;
    SetVolume(RightSid, rightVol);
    SetVolume(LeftSid, leftVol);
    frames := PanFrames;
End;

// Plays one note on both voices until it's stopped, starting on the
// right
Procedure StartPan;
Begin
    StopEverything;
    Writeln('Pan');
    rightVol := 15;
    leftVol := 0;
    SetVolume(RightSid, rightVol);
    SetVolume(LeftSid, leftVol);
    PlayNote(RightVoice, 4 * 12 + NoteA, 0);
    PlayNote(LeftVoice, 4 * 12 + NoteA, 0);
    panning := True;
    panToLeft := True;
    frames := PanFrames;
End;

Begin
    bouncing := False;
    panning := False;
    frames := 0;
    SetUpVoices;
    ShowMenu;

    Repeat
        WaitFrame;
        ch := GetKeyNoWait;
        Case ch Of
            '1': StartBounce;
            '2': StartPan;
            '0': Begin
                StopEverything;
                Writeln('Stop');
            End;
        End;
        If frames > 0 Then Dec(frames);
        If frames = 0 Then Begin
            If bouncing Then Bounce
            Else If panning Then PanStep;
        End;
    Until (ch = 'q') Or (ch = 'Q');

    StopEverything;
End.
