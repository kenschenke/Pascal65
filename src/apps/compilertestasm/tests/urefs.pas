// A unit for unitrefs.pas. The program reaches each kind of entry from
// outside: routines it calls and takes the address of, a record it passes
// by value and a dynamic array it sizes. The routines' bodies are in a
// different order from the interface's, which numbers the entries.

Unit URefs;

Interface

Type
    Pt = Record
        x, y : Integer;
    End;

Var
    origin : Pt;
    vals : Array Of Integer;
    calls : Integer;

Function PtSum(p : Pt) : Integer;
Procedure Bump(n : Integer);

Implementation

Var
    privCount : Integer;

Procedure Bump(n : Integer);
Begin
    privCount := privCount + 1;
    calls := calls + n;
End;

Function PtSum(p : Pt) : Integer;
Begin
    // A call to an interface routine from inside the unit
    Bump(1);
    // p is a copy, so the caller's record keeps its x
    p.x := p.x + 100;
    PtSum := p.x + p.y;
End;

End.
