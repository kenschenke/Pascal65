// Error Test 8 - Array assignment, parameters, return types and literals

Program TestArrayRules;

Type
    TDyn = Array Of Integer;
    TStat = Array[1..5] Of Integer;

Var
    d1, d2 : TDyn;
    a : Array Of Integer;
    s1, s2 : TStat;
    i : Integer;
    lit : Array Of Integer = (1, 2, 3, 4, 5, 6, 7);
    litd : TDyn = (10, 20);

Procedure TakeDyn(p : TDyn); Begin End;
Procedure TakeDynVar(Var p : TDyn); Begin End;
Procedure TakeStat(p : TStat); Begin End;
Procedure TakeStatVar(Var p : TStat); Begin End;
Procedure TakeOpen(p : Array Of Integer); Begin End;
Function RetInt : Integer; Begin RetInt := 1; End;
Function RetStat : TStat; Begin i := 1; (* $ExpectError 71 *) End;
Function RetDyn : TDyn; Begin i := 1; (* $ExpectError 71 *) End;

Begin
    // Element assignment is allowed
    d1[0] := 5;
    s1[1] := d1[0];
    d1[0] := s1[2];
    a[i] := lit[i] + litd[i];

    // Whole-array assignment is not
    d1 := d2;                   (* $ExpectError 70 *)
    s1 := s2;                   (* $ExpectError 70 *)
    a := d1;                    (* $ExpectError 70 *)

    // Static and dynamic array arguments must match the parameter
    TakeDyn(d1);
    TakeDyn(a);
    TakeDynVar(d1);
    TakeStat(s1);
    TakeStatVar(s1);
    TakeOpen(d1);
    TakeDyn(s1);                (* $ExpectError 72 *)
    TakeDynVar(s1);             (* $ExpectError 72 *)
    TakeStat(d1);               (* $ExpectError 72 *)
    TakeStatVar(d1);            (* $ExpectError 72 *)
    TakeOpen(s1);               (* $ExpectError 72 *)
    i := RetInt;
End.
