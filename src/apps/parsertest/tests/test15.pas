(* Test 15 - Array literals
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE row
      T:TYPE-ARRAY  1.. 2 OF TYPE-INTEGER
    D:DECL-TYPE plane
      T:TYPE-ARRAY  1.. 2 OF TYPE-DECLARED
    D:DECL-VARIABLE arr1
      T:TYPE-ARRAY  1.. 5 OF TYPE-INTEGER
      E:EXPR-ARRAY-LITERAL
        EXPR-BYTE-LITERAL 10
        EXPR-BYTE-LITERAL 20
        EXPR-BYTE-LITERAL 30
    D:DECL-VARIABLE arr2
      T:TYPE-ARRAY  1.. 3 OF TYPE-ARRAY  1.. 5 OF TYPE-INTEGER
      E:EXPR-ARRAY-LITERAL
        EXPR-ARRAY-LITERAL
          EXPR-BYTE-LITERAL 11
          EXPR-BYTE-LITERAL 21
          EXPR-BYTE-LITERAL 31
        EXPR-ARRAY-LITERAL
          EXPR-BYTE-LITERAL 12
          EXPR-BYTE-LITERAL 22
          EXPR-BYTE-LITERAL 32
          EXPR-BYTE-LITERAL 42
        EXPR-ARRAY-LITERAL
          EXPR-BYTE-LITERAL 13
          EXPR-BYTE-LITERAL 23
          EXPR-BYTE-LITERAL 33
          EXPR-BYTE-LITERAL 43
          EXPR-BYTE-LITERAL 53
    D:DECL-VARIABLE arr3
      T:TYPE-ARRAY  1.. 2 OF TYPE-DECLARED
      E:EXPR-ARRAY-LITERAL
        EXPR-ARRAY-LITERAL
          EXPR-ARRAY-LITERAL
            EXPR-BYTE-LITERAL 1
            EXPR-BYTE-LITERAL 2
          EXPR-ARRAY-LITERAL
            EXPR-BYTE-LITERAL 3
            EXPR-BYTE-LITERAL 4
        EXPR-ARRAY-LITERAL
          EXPR-ARRAY-LITERAL
            EXPR-BYTE-LITERAL 5
            EXPR-BYTE-LITERAL 6
          EXPR-ARRAY-LITERAL
            EXPR-BYTE-LITERAL 7
            EXPR-BYTE-LITERAL 8
*)

Program Test;

Type
  Row = Array[1..2] Of Integer;
  Plane = Array[1..2] Of Row;

Var
  arr1 : Array[1..5] Of Integer = ($10, $20, $30);
  arr2 : Array[1..3,1..5] Of Integer =
    ( ($11, $21, $31), ($12, $22, $32, $42), ($13, $23, $33, $43, $53) );
  arr3 : Array[1..2] Of Plane =
    ( ( (1, 2), (3, 4) ), ( (5, 6), (7, 8) ) );

Begin
End.
