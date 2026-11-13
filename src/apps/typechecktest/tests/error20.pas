// Error Test 20 - Pointers to pointers and fields through pointers
//
// p^^ is what p^ points to, and a field of p^^ or of an array element's
// pointer is a field of the record it points to. The type checker took
// p^^ as a pointer, and crashed on pp^^.y and ptrs[2]^.y. Only a pointer
// can be dereferenced.

Program Ptrs;

Type
    Point = Record
        x, y : Integer;
    End;
    PointPtr = ^Point;
    IntPtr = ^Integer;

Var
    i : Integer;
    ch : Char;
    pt : Point;
    ip : IntPtr;
    ipp : ^IntPtr;
    pp : ^PointPtr;
    ptrs : Array[1..3] Of PointPtr;

Begin
    i := ipp^^;
    ipp^^ := i;
    ipp^ := ip;
    i := pp^^.y;
    pp^^.y := i;
    pt := pp^^;
    i := ptrs[2]^.y;
    ptrs[2]^.y := i;
    i := i^;                        (* $ExpectError 30 *) (* $ExpectError 38 *)
    pt := pt^;                      (* $ExpectError 30 *) (* $ExpectError 38 *)
    ch := ipp^^;                    (* $ExpectError 38 *)
    ch := pp^^.x;                   (* $ExpectError 38 *)
    ch := ptrs[1]^.x;               (* $ExpectError 38 *)
End.
