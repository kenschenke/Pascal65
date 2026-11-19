Program Slots256;

// The program and its unit fill all 256 level 1 slots: the program's 56
// variables take 0 to 55 and S256U's 200 take 56 to 255. A variable
// operand's offset is one byte, so u199, in the last slot, is the last
// variable a program can have. It must not land on another.

(* $StackSize 2048 *)

Uses S256U;

Var
    anyErrors : Boolean;
    errList : String;
    p000, p001, p002, p003, p004, p005, p006, p007, p008, p009 : Integer;
    p010, p011, p012, p013, p014, p015, p016, p017, p018, p019 : Integer;
    p020, p021, p022, p023, p024, p025, p026, p027, p028, p029 : Integer;
    p030, p031, p032, p033, p034, p035, p036, p037, p038, p039 : Integer;
    p040, p041, p042, p043, p044, p045, p046, p047, p048, p049 : Integer;
    p050, p051, p052, p053 : Integer;

Procedure Error(num : Integer);
Begin
    Writeln('Slots256 (', num, ')');
    anyErrors := true;
    If Length(errList) < 60 Then errList := errList + WriteStr(' ', num);
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
    If Length(acc) < 150 Then acc := acc + 'slots256:' + errList + '; ';
    Assign(f, 'testfailed');
    Rewrite(f);
    Writeln(f, acc);
    Close(f);
End;

Begin
    anyErrors := false;
    errList := '';

    Writeln('Running 256 slot tests');

    p000 := 1;
    p053 := 53;
    u198 := 198;
    SetEnds(7, 4321);
    If u000 <> 7 Then Error(1);
    If u199 <> 4321 Then Error(2);
    If GetLast <> 4321 Then Error(3);
    If GetFirst <> 7 Then Error(4);
    u199 := 99;
    If GetLast <> 99 Then Error(5);
    If u198 <> 198 Then Error(6);
    If p053 <> 53 Then Error(7);
    If p000 <> 1 Then Error(8);
    If u001 <> 0 Then Error(9);

    If anyErrors Then ReportFailure;
End.
