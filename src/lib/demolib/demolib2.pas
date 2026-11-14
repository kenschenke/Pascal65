(*
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Demo Library 2
 * 
 * Copyright (c) 2026
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)


(*
    The twin of DemoLib in the v2 library format (a relocation table).
    It has every DemoLib routine and two that test the format.
*)
Unit DemoLib2;

Interface

Type
    DemoArray = Array[1..10] Of Integer;
    DemoRecord = Record
        a, b : Integer;
    End;
    DemoProc = Procedure(num : Integer);
    DemoFunc = Function : Integer;

Var
    PublicInt : Integer;
    PublicArray : DemoArray;
    PublicRecord : DemoRecord;
    PublicString : String;

Function DemoArea(w, h : Integer) : Integer;
Procedure DoubleParam(Var i : Integer);
Function Biggest(arr : DemoArray) : Integer;
Function LastChar(str : String) : Char;
Function SumOfRecord(rec : DemoRecord) : Integer;
Procedure AppendToString(Var source : String; toAppend : String);
Procedure DoubleArray(Var arr : DemoArray);
Procedure DoubleRecord(Var rec : DemoRecord);
Procedure DoublePublicInt;
Procedure DoublePublicArray;
Procedure DoublePublicRecord;
Procedure AppendToPublicString(str : String);
Procedure RegisterDemoProc(callback : DemoProc);
Procedure TestDemoProc(num : Integer);
Procedure RegisterDemoFunc(callback : DemoFunc);
Function TestDemoFunc : Integer;

// Returns 250 if the bytes in the library's own page range are unchanged
Function PageBytes : Integer;
// Returns 1, then 2, ... if the BSS was zeroed and init ran
Function BssCounter : Integer;

Implementation Library

End.
