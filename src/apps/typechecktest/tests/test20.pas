(* Test 20 - String comparisons
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE s
      T:TYPE-STRING-VAR
    D:DECL-VARIABLE t
      T:TYPE-STRING-VAR
    D:DECL-VARIABLE c
      T:TYPE-CHARACTER
    D:DECL-VARIABLE a
      T:TYPE-ARRAY  1.. 4 OF TYPE-CHARACTER
    D:DECL-VARIABLE b
      T:TYPE-BOOLEAN
    D:DECL-TYPE f
      T:TYPE-FUNCTION
        return: TYPE-STRING-VAR
        param: n
          T:TYPE-INTEGER
      S:STMT-BLOCK
        D:DECL-VARIABLE f
          T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-EQ T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-NAME t T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-NE T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-NAME t T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-LT T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-NAME t T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-LTE T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-NAME t T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-GT T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-NAME t T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-GTE T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-NAME t T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-EQ T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-STRING-LITERAL abc T:TYPE-STRING-LITERAL
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-NE T:TYPE-BOOLEAN
          Left:EXPR-STRING-LITERAL abc T:TYPE-STRING-LITERAL
          Right:EXPR-NAME s T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-LT T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-NAME c T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-LTE T:TYPE-BOOLEAN
          Left:EXPR-NAME c T:TYPE-CHARACTER
          Right:EXPR-NAME s T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-GT T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-CHARACTER-LITERAL 'x' T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-GTE T:TYPE-BOOLEAN
          Left:EXPR-CHARACTER-LITERAL 'x' T:TYPE-CHARACTER
          Right:EXPR-NAME s T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-EQ T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-NAME a T:TYPE-ARRAY
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-NE T:TYPE-BOOLEAN
          Left:EXPR-NAME a T:TYPE-ARRAY
          Right:EXPR-NAME s T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-LT T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-ADD T:TYPE-STRING-OBJ
            Left:EXPR-NAME s T:TYPE-STRING-VAR
            Right:EXPR-NAME t T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-GT T:TYPE-BOOLEAN
          Left:EXPR-ADD T:TYPE-STRING-OBJ
            Left:EXPR-NAME s T:TYPE-STRING-VAR
            Right:EXPR-NAME t T:TYPE-STRING-VAR
          Right:EXPR-NAME s T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-LTE T:TYPE-BOOLEAN
          Left:EXPR-NAME s T:TYPE-STRING-VAR
          Right:EXPR-CALL T:TYPE-STRING-VAR
            Left:EXPR-NAME f T:TYPE-FUNCTION
            Right:EXPR-ARG
              EXPR-BYTE-LITERAL 1 T:TYPE-SHORTINT
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-GTE T:TYPE-BOOLEAN
          Left:EXPR-CALL T:TYPE-STRING-VAR
            Left:EXPR-NAME f T:TYPE-FUNCTION
            Right:EXPR-ARG
              EXPR-BYTE-LITERAL 1 T:TYPE-SHORTINT
          Right:EXPR-NAME s T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BOOLEAN
        Left:EXPR-NAME b T:TYPE-BOOLEAN
        Right:EXPR-EQ T:TYPE-BOOLEAN
          Left:EXPR-NAME c T:TYPE-CHARACTER
          Right:EXPR-CHARACTER-LITERAL 'y' T:TYPE-CHARACTER
*)

// A String compares with a String, a string literal, a Char, a Char
// literal, an array of Char, a concatenation and a function result, in
// either order, with each of the six operators. The result is a Boolean.
// A Char with a Char is still an ordinal comparison.

Program Test;

Var
  s, t : String;
  c : Char;
  a : Array[1..4] Of Char;
  b : Boolean;

Function F(n : Integer) : String;
Begin
End;

Begin
  b := s = t;
  b := s <> t;
  b := s < t;
  b := s <= t;
  b := s > t;
  b := s >= t;
  b := s = 'abc';
  b := 'abc' <> s;
  b := s < c;
  b := c <= s;
  b := s > 'x';
  b := 'x' >= s;
  b := s = a;
  b := a <> s;
  b := s < s + t;
  b := s + t > s;
  b := s <= F(1);
  b := F(1) >= s;
  b := c = 'y';
End.
