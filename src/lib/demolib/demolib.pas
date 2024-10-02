(*
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Demo Library
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
*)


(*
    Things to demo:
       * Processing a scalar parameter by value
       * Processing a scalar parameter by reference and updating value
       * Processing an array parameter
       * Processing a string parameter
       * Processing a record parameter
       * Returning a value
       * Reading and writing a scalar interface variable
       * Reading and writing an array interface variable
       * Reading and writing a record interface variable
       * Reading and modifying a string interface variable
*)
Unit DemoLib;

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

Implementation Library

End.
