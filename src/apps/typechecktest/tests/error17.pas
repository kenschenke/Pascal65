// Error Test 17 - Routine calls and parameters
//
// Recursive calls, calls of things that aren't routines, record, pointer,
// routine pointer, Var, String and file parameters, array parameters and
// routine pointer assignments and pointer assignments.

Program Calls;

Type
    Color = (Red, Green, Blue);
    Shade = (Light, Dark);
    TRec = Record a : Integer; End;
    TOther = Record a : Integer; End;
    TArr = Array[1..3] Of Byte;
    TWords = Array[1..3] Of Word;
    TLow = Array[0..2] Of Byte;
    TBig = Array[1..300] Of Byte;
    TProc = Procedure;
    TProcInt = Procedure(n : Integer);
    PInt = ^Integer;
    PRec = ^TRec;
    TIntFile = File Of Integer;

Const
    KW = 1000;

Var
    b : Byte;
    i : Integer;
    ch : Char;
    str : String;
    rec : TRec;
    other : TOther;
    arr : TArr;
    words : TWords;
    low : TLow;
    big : TBig;
    pi : PInt;
    pb : ^Byte;
    pi2 : PInt;
    pr1, pr2 : PRec;
    poth : ^TOther;
    cb : TProc;
    cbi : TProcInt;
    fi : TIntFile;
    fr : File Of TRec;
    t : Text;

Function Fact(n : Integer) : Integer;
Begin
    If n < 2 Then Fact := 1 Else Fact := n * Fact(n - 1);
End;

Procedure TakeRec(r : TRec); Begin i := 1; End;
Procedure TakePtr(p : PInt); Begin i := 1; End;
Procedure TakeVarPtr(Var p : PInt); Begin i := 1; End;
Procedure TakeRecPtr(p : PRec); Begin i := 1; End;
Procedure TakeProc(p : TProc); Begin i := 1; End;
Procedure TakeVarInt(Var n : Integer); Begin i := 1; End;
Procedure TakeVarChar(Var c : Char); Begin i := 1; End;
Procedure TakeStr(s : String); Begin i := 1; End;
Procedure TakeVarStr(Var s : String); Begin i := 1; End;
Procedure TakeFile(Var f : File); Begin i := 1; End;
Procedure TakeIntFile(Var f : TIntFile); Begin i := 1; End;
Procedure TakeValFile(f : File); Begin i := 1; End;
Procedure TakeArr(a : TArr); Begin i := 1; End;
Procedure TakeArrVar(Var a : TArr); Begin i := 1; End;
// A Var parameter passed on
Procedure PassArr(Var a : TArr); Begin TakeArrVar(a); TakeArr(a); End;
Procedure NoParams; Begin i := 1; End;
Procedure IntParam(n : Integer); Begin i := n; End;
Procedure CharParam(c : Char); Begin i := 1; End;
Procedure TakeColor(c : Color); Begin i := 1; End;
Procedure TakeVarWord(Var n : Word); Begin i := 1; End;

Begin
    i := Fact(5);
    pi := @Fact;
    TakeColor(Green);
    TakeColor(Light);               (* $ExpectError 30 *)
    i := b(1);          (* $ExpectError 8 *) (* $ExpectError 38 *)

    // Records
    TakeRec(rec);
    TakeRec(other);                 (* $ExpectError 30 *)

    // Pointers
    TakePtr(pi);
    TakePtr(@i);
    TakePtr(@b);                    (* $ExpectError 35 *)
    TakePtr(pi2);
    TakePtr(pb);                    (* $ExpectError 35 *)
    TakeVarPtr(pi);
    TakeVarPtr(pb);                 (* $ExpectError 35 *)
    TakeVarPtr(@i);                 (* $ExpectError 51 *)
    TakeRecPtr(pr1);
    TakeRecPtr(@rec);
    TakeRecPtr(poth);               (* $ExpectError 35 *)
    TakeRecPtr(@other);             (* $ExpectError 35 *)

    // Pointer assignments
    pi := pi2;
    pr1 := pr2;
    pi := pb;                       (* $ExpectError 38 *)
    pb := pi;                       (* $ExpectError 38 *)
    pr1 := poth;                   (* $ExpectError 38 *)
    pr1 := @rec;
    pr1 := @other;                 (* $ExpectError 38 *)
    pi := nil;

    // Routine pointers
    TakeProc(@NoParams);
    TakeProc(@IntParam);            (* $ExpectError 50 *)
    cb := @NoParams;
    cbi := @IntParam;
    cbi := @CharParam;              (* $ExpectError 35 *)
    cb := @i;                       (* $ExpectError 38 *)
    cb := @GetKey;                  (* $ExpectError 38 *)

    // Var parameters
    TakeVarInt(i);
    TakeVarInt(b);                  (* $ExpectError 51 *)
    TakeVarInt(5);                  (* $ExpectError 51 *)
    TakeVarInt(i + 1);              (* $ExpectError 51 *)
    TakeVarWord(KW);                (* $ExpectError 51 *)
    TakeVarChar(ch);
    TakeVarChar('x');               (* $ExpectError 51 *)
    TakeVarChar(str[1]);
    TakeVarChar(pi);    (* $ExpectError 30 *) (* $ExpectError 51 *)

    // Strings
    TakeStr('abc');
    TakeStr(ch);
    TakeStr(i);                     (* $ExpectError 30 *)
    TakeVarStr(str);
    TakeVarStr(ch);                 (* $ExpectError 30 *)

    // Files
    TakeFile(fi);
    TakeFile(t);
    TakeIntFile(fi);
    TakeIntFile(fr);                (* $ExpectError 30 *)
    TakeFile(i);                    (* $ExpectError 30 *)
    TakeValFile(fi);                (* $ExpectError 30 *)

    // Arrays
    TakeArr(arr);
    TakeArr(words);                 (* $ExpectError 30 *)
    TakeArr(low);       (* $ExpectError 30 *) (* $ExpectError 30 *)
    TakeArr(big);       (* $ExpectError 30 *) (* $ExpectError 30 *)
End.
