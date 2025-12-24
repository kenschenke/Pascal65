(* Test 9 - Arrays
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE arr1
      T:TYPE-ARRAY  1.. 5 OF TYPE-INTEGER
    D:DECL-VARIABLE arr2
      T:TYPE-ARRAY  0.. 4 OF TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-SUBSCRIPT
          Left:EXPR-NAME arr1
          Right:EXPR-BYTE-LITERAL 3
        Right:EXPR-BYTE-LITERAL 5
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-SUBSCRIPT
          Left:EXPR-NAME arr1
          Right:EXPR-ADD
            Left:EXPR-NAME i
            Right:EXPR-BYTE-LITERAL 1
        Right:EXPR-BYTE-LITERAL 6
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-SUBSCRIPT
          Left:EXPR-SUBSCRIPT
            Left:EXPR-NAME arr2
            Right:EXPR-BYTE-LITERAL 3
          Right:EXPR-BYTE-LITERAL 5
        Right:EXPR-BYTE-LITERAL 2
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-SUBSCRIPT
          Left:EXPR-SUBSCRIPT
            Left:EXPR-NAME arr2
            Right:EXPR-ADD
              Left:EXPR-NAME i
              Right:EXPR-BYTE-LITERAL 1
          Right:EXPR-MUL
            Left:EXPR-NAME i
            Right:EXPR-BYTE-LITERAL 3
        Right:EXPR-BYTE-LITERAL 7
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-SUBSCRIPT
          Left:EXPR-SUBSCRIPT
            Left:EXPR-NAME arr2
            Right:EXPR-NAME i
          Right:EXPR-ADD
            Left:EXPR-NAME j
            Right:EXPR-BYTE-LITERAL 1
        Right:EXPR-BYTE-LITERAL 8
*)

Program Test;

Var
  arr1 : Array[1..5] Of Integer;
  arr2 : Array[5] Of Integer;

Begin
  arr1[3] := 5;
  arr1[i+1] := 6;
  arr2[3,5] := 2;
  arr2[i+1,i*3] := 7;
  arr2[i][j+1] := 8;
End.
