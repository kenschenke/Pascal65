// Error Test 13 - Subrange operands
//
// A variable of a subrange type compares as its subrange's integer or
// character type. 1..1000 is a Word, so comparing it with an Integer is a
// mixed sign comparison.

Program SubOps;

Type
    Small = 1..1000;
    Letter = 'a'..'z';
    Color = (Red, Green, Blue);
    Warm = Red..Green;

Var
    s : Small;
    g : -5..5;
    l : Letter;
    w : Warm;
    i : Integer;
    bool : Boolean;

Begin
    bool := s <> 1000;
    bool := g >= 0;
    bool := s < i;      (* $ExpectWarn 67 *)
    bool := g = i;
    bool := l <> 'q';
    bool := l < l;
    bool := w = Green;
    bool := l = 1;      (* $ExpectError 35 *)
    bool := s = 'q';    (* $ExpectError 35 *)
End.
