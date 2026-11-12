(* Test 20 - Unary minus
D:DECL-TYPE test20
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-VARIABLE r
      T:TYPE-REAL
    D:DECL-VARIABLE a
      T:TYPE-ARRAY  1.. 3 OF TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-NEGATE
          Left:EXPR-ADD
            Left:EXPR-NAME i
            Right:EXPR-BYTE-LITERAL 1
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-BYTE-LITERAL -5
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-BYTE-LITERAL 5
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-NEGATE
          Left:EXPR-SUBSCRIPT
            Left:EXPR-NAME a
            Right:EXPR-BYTE-LITERAL 2
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-NEGATE
          Left:EXPR-CALL
            Left:EXPR-NAME f
            Right:EXPR-ARG
              EXPR-BYTE-LITERAL 1
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-NEGATE
          Left:EXPR-TYPE-CAST T:TYPE-INTEGER
            Left:EXPR-NAME r
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-SUB
          Left:EXPR-NAME i
          Right:EXPR-NEGATE
            Left:EXPR-NAME i
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-MUL
          Left:EXPR-NEGATE
            Left:EXPR-NAME i
          Right:EXPR-BYTE-LITERAL 2
*)

// A minus before a number flips the literal's sign. Anything else is
// put under an EXPR_NEGATE.

Program Test20;

Var
    i : Integer;
    r : Real;
    a : Array[1..3] Of Integer;

Begin
    i := -(i + 1);
    i := -(5);
    i := -(-5);
    i := -a[2];
    i := -F(1);
    i := -Integer(r);
    i := i - -i;
    i := -i * 2;
End.
