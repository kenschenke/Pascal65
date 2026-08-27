(* Test 13 - Operators and Expressions
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME a
        Right:EXPR-ADD
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 1
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME a
        Right:EXPR-MUL
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 3
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME a
        Right:EXPR-SUB
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 5
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME a
        Right:EXPR-DIV
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 4
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME a
        Right:EXPR-DIVINT
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 6
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME a
        Right:EXPR-MOD
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 2
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME c
        Right:EXPR-LT
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 2
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME c
        Right:EXPR-LTE
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 8
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME c
        Right:EXPR-GT
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 7
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME c
        Right:EXPR-GTE
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 9
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME c
        Right:EXPR-NE
          Left:EXPR-NAME b
          Right:EXPR-BYTE-LITERAL 1
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME d
        Right:EXPR-AND
          Left:EXPR-LT
            Left:EXPR-NAME b
            Right:EXPR-BYTE-LITERAL 2
          Right:EXPR-GTE
            Left:EXPR-NAME d
            Right:EXPR-BYTE-LITERAL 5
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME d
        Right:EXPR-OR
          Left:EXPR-GT
            Left:EXPR-NAME b
            Right:EXPR-BYTE-LITERAL 5
          Right:EXPR-NE
            Left:EXPR-NAME d
            Right:EXPR-BYTE-LITERAL 6
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME d
        Right:EXPR-NOT
          Left:EXPR-GT
            Left:EXPR-NAME b
            Right:EXPR-BYTE-LITERAL 6
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME e
        Right:EXPR-BITWISE-AND
          Left:EXPR-NAME a
          Right:EXPR-NAME b
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME e
        Right:EXPR-BITWISE-OR
          Left:EXPR-NAME a
          Right:EXPR-NAME b
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME e
        Right:EXPR-BITWISE-LSHIFT
          Left:EXPR-NAME a
          Right:EXPR-BYTE-LITERAL 4
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME e
        Right:EXPR-BITWISE-RSHIFT
          Left:EXPR-NAME a
          Right:EXPR-BYTE-LITERAL 5
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME e
        Right:EXPR-NOT
          Left:EXPR-NAME a
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME e
        Right:EXPR-BITWISE-XOR
          Left:EXPR-NAME a
          Right:EXPR-NAME b
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME f
        Right:EXPR-ADD
          Left:EXPR-NAME b
          Right:EXPR-MUL
            Left:EXPR-NAME c
            Right:EXPR-BYTE-LITERAL 5
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME f
        Right:EXPR-MUL
          Left:EXPR-ADD
            Left:EXPR-NAME b
            Right:EXPR-NAME c
          Right:EXPR-BYTE-LITERAL 5
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME s
        Right:EXPR-ADD
          Left:EXPR-NAME b
          Right:EXPR-STRING-LITERAL World
*)

Program Test;

Begin
  a := b + 1;
  a := b * 3;
  a := b - 5;
  a := b / 4;
  a := b Div 6;
  a := b Mod 2;
  c := b < 2;
  c := b <= 8;
  c := b > 7;
  c := b >= 9;
  c := b <> 1;
  d := (b < 2) And (d >= 5);
  d := (b > 5) Or (d <> 6);
  d := Not (b > 6);
  e := a & b;
  e := a ! b;
  e := a << 4;
  e := a >> 5;
  e := Not a;
  e := a Xor b;
  f := b + c * 5;
  f := (b + c) * 5;
  s := b + 'World';
End.
