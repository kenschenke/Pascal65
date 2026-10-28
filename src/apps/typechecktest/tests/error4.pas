// Error Test 4 - Comparison warnings and errors

Program TestCast;

Var
    b : Byte;
    s : ShortInt;
    w : Word;
    i : Integer;
    c : Cardinal;
    l : LongInt;

Begin
    // Byte Tests
    If b < s Then Begin End;        (* $ExpectWarn 67 *)
    If b < w Then Begin End;
    If b < i Then Begin End;        (* $ExpectWarn 67 *)
    If b < c Then Begin End;
    If b < l Then Begin End;        (* $ExpectWarn 67 *)
    If b < 200 Then Begin End;
    If 200 > b Then Begin End;
    If b < -123 Then Begin End;     (* $ExpectWarn 67 *)
    If -123 < b Then Begin End;     (* $ExpectWarn 67 *)
    If b < 12345 Then Begin End;
    If 12345 > b Then Begin End;
    If b < -12345 Then Begin End;   (* $ExpectWarn 67 *)
    If -12345 < b Then Begin End;   (* $ExpectWarn 67 *)
    If b < 123456 Then Begin End;
    If 123456 > b Then Begin End;
    If b < -123456 Then Begin End;  (* $ExpectWarn 67 *)
    If -123456 < b Then Begin End;  (* $ExpectWarn 67 *)

    // ShortInt Tests
    If s < b Then Begin End;        (* $ExpectWarn 67 *)
    If s < w Then Begin End;        (* $ExpectWarn 67 *)
    If s < i Then Begin End;
    If s < c Then Begin End;        (* $ExpectWarn 67 *)
    If s < l Then Begin End;
    If s < -123 Then Begin End;
    If -123 < s Then Begin End;
    If s < 200 Then Begin End;
    If 200 < s Then Begin End;
    If s < 12345 Then Begin End;
    If 12345 < s Then Begin End;
    If s < -12345 Then Begin End;
    If -12345 < s Then Begin End;
    If s < 123456 Then Begin End;
    If 123456 > s Then Begin End;
    If s < -123456 Then Begin End;
    If -123456 < s Then Begin End;

    // Word Tests
    If w < b Then Begin End;
    If w < s Then Begin End;        (* $ExpectWarn 67 *)
    If w < i Then Begin End;        (* $ExpectWarn 67 *)
    If w < c Then Begin End;
    If w < l Then Begin End;        (* $ExpectWarn 67 *)
    If w < -123 Then Begin End;     (* $ExpectWarn 67 *)
    If -123 < w Then Begin End;     (* $ExpectWarn 67 *)
    If w < 123 Then Begin End;
    If 123 < w Then Begin End;
    If w < -12345 Then Begin End;   (* $ExpectWarn 67 *)
    If -12345 < w Then Begin End;   (* $ExpectWarn 67 *)
    If w < 12345 Then Begin End;
    If 12345 < w Then Begin End;
    If w < -123456 Then Begin End;  (* $ExpectWarn 67 *)
    If -123456 < w Then Begin End;  (* $ExpectWarn 67 *)
    If w < 123456 Then Begin End;
    If 123456 < w Then Begin End;

    // Integer Tests
    If i < b Then Begin End;        (* $ExpectWarn 67 *)
    If i < s Then Begin End;
    If i < w Then Begin End;        (* $ExpectWarn 67 *)
    If i < c Then Begin End;        (* $ExpectWarn 67 *)
    If i < l Then Begin End;
    If i < 123 Then Begin End;
    If 123 < i Then Begin End;
    If i < -123 Then Begin End;
    If -123 < i Then Begin End;
    If i < -12345 Then Begin End;
    If -12345 < i Then Begin End;
    If i < 12345 Then Begin End;
    If 12345 < i Then Begin End;
    If i < -123456 Then Begin End;
    If -123456 < i Then Begin End;
    If i < 123456 Then Begin End;
    If 123456 < i Then Begin End;

    // Cardinal Tests
    If c < b Then Begin End;
    If c < s Then Begin End;        (* $ExpectWarn 67 *)
    If c < w Then Begin End;
    If c < i Then Begin End;        (* $ExpectWarn 67 *)
    If c < l Then Begin End;        (* $ExpectWarn 67 *)
    If c < 123 Then Begin End;
    If 123 < c Then Begin End;
    If c < -123 Then Begin End;     (* $ExpectWarn 67 *)
    If -123 < c Then Begin End;     (* $ExpectWarn 67 *)
    If c < 12345 Then Begin End;
    If 12345 < c Then Begin End;
    If c < -12345 Then Begin End;   (* $ExpectWarn 67 *)
    if -12345 < c Then Begin End;   (* $ExpectWarn 67 *)
    If c < 123456 Then Begin End;
    If 123456 < c Then Begin End;
    If c < -123456 Then Begin End;  (* $ExpectWarn 67 *)
    If -123456 < c Then Begin End;  (* $ExpectWarn 67 *)

    // LongInt Tests
    If l < b Then Begin End;        (* $ExpectWarn 67 *)
    If l < s Then Begin End;
    If l < w Then Begin End;        (* $ExpectWarn 67 *)
    If l < i Then Begin End;
    If l < c Then Begin End;        (* $ExpectWarn 67 *)
    If l < 123 Then Begin End;
    If 123 < l Then Begin End;
    If l < -123 Then Begin End;
    If 123 < l Then Begin End;
    If l < 12345 Then Begin End;
    If 12345 < l Then Begin End;
    If l < -12345 Then Begin End;
    If -12345 < l Then Begin End;
    If l < 123456 Then Begin End;
    If 123456 < l Then Begin End;
    If l < -123456 Then Begin End;
    If -123456 < l Then Begin End;
End.
