Program IrqCb;

// Tests the callbacks the System and Sprites libraries run from the
// raster interrupt (SetRasterCallback and SetCollisionCallback).
//
// A callback must leave the CPU stack as it found it, or the program
// crashes after a few hundred calls, and must find the program's
// variables wherever the interrupt stopped it. It must also save the
// runtime's zero page, or the program's own arithmetic goes wrong while
// the callbacks run. soundseq tests the Sound library's callback.

Uses Sprites;

Const
    VicCtrl1 = $D011;   // Bit 7 is bit 8 of the raster line

Var
    anyErrors : Boolean;
    errList : String;
    rasterOn : Boolean;
    rasterCount, collisions, sToS : Cardinal;
    lastBits : Byte;
    i, n : Word;
    x : Cardinal;
    data : Array[1..63] Of Byte;

Procedure Error(num : Integer);
Begin
    Writeln('IrqCb (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
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

// The raster callback. Its local variable and the arithmetic use the
// runtime stack and zero page.
Procedure OnRaster;
Var
    w : Cardinal;
Begin
    If rasterOn Then Begin
        w := rasterCount * 2;
        rasterCount := w Div 2 + 1;
    End;
End;

Procedure OnCollision(spriteBits : Byte; isSToS : Boolean);
Begin
    collisions := collisions + 1;
    If isSToS Then Begin
        sToS := sToS + 1;
        lastBits := spriteBits;
    End;
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
    If Length(acc) < 150 Then acc := acc + 'irqcb:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    Writeln('Running IRQ callback tests');

    anyErrors := false;
    errList := '';
    rasterOn := False;
    rasterCount := 0;
    collisions := 0;
    sToS := 0;
    lastBits := 0;

    // The raster callback runs once a frame
    SetRasterCallback(@OnRaster);
    WaitFrames(1);
    rasterOn := True;
    WaitFrames(50);
    rasterOn := False;
    If (rasterCount < 49) Or (rasterCount > 51) Then Error(1);

    // The program's arithmetic goes on while it runs, for a few hundred
    // frames, so a byte left on the CPU stack each call would crash it
    rasterOn := True;
    For n := 1 To 4 Do
        For i := 1 To 3000 Do Begin
            x := i * 3 + 7;
            If x <> i + i + i + 7 Then Error(2);
        End;
    rasterOn := False;
    If rasterCount < 100 Then Error(3);

    // Two sprites in the same place collide each frame
    For i := 1 To 63 Do data[i] := 255;
    SpriteData(0, @data[1]);
    SpriteData(1, @data[1]);
    SpritePos(0, 100, 100);
    SpritePos(1, 100, 100);
    SetCollisionCallback(@OnCollision);
    Sprite(0, 1, True, False);
    Sprite(1, 2, True, False);
    WaitFrames(20);
    Sprite(0, 1, False, False);
    Sprite(1, 2, False, False);
    If sToS = 0 Then Error(10);
    If (lastBits & 3) <> 3 Then Error(11);
    For i := 1 To 3000 Do Begin
        x := i * 5 + 1;
        If x <> i + i + i + i + i + 1 Then Error(12);
    End;

    If anyErrors Then ReportFailure;
End.
