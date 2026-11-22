(* String Overflow Test *)

Program StrOvf;

// Ends with a runtime error: an array of 256 Chars is too long to be a
// string, so comparing it is rteStringOverflow (arrayLength in the
// runtime). It once compared as an empty string. rtdyntest.sh runs it
// and checks the message.

Var
    a : Array[1..256] Of Char;
    i : Integer;

Begin
    Writeln('String overflow test');
    For i := 1 To 256 Do a[i] := 'x';
    If a = '' Then Writeln('Compared as empty');
    Writeln('Not reached');
End.
