(* Test 19 - Arithmetic between two constants
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-CONST w
      T:TYPE-WORD
      E:EXPR-WORD-LITERAL 4d2 T:TYPE-INTEGER
    D:DECL-CONST n
      T:TYPE-INTEGER
      E:EXPR-WORD-LITERAL -1f4 T:TYPE-INTEGER
    D:DECL-CONST c
      T:TYPE-CARDINAL
      E:EXPR-DWORD-LITERAL 186a0 T:TYPE-LONGINT
    D:DECL-VARIABLE r
      T:TYPE-LONGINT
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-LONGINT
        Left:EXPR-NAME r T:TYPE-LONGINT
        Right:EXPR-ADD T:TYPE-LONGINT
          Left:EXPR-NAME w T:TYPE-WORD
          Right:EXPR-NAME n T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-LONGINT
        Left:EXPR-NAME r T:TYPE-LONGINT
        Right:EXPR-ADD T:TYPE-LONGINT
          Left:EXPR-NAME n T:TYPE-INTEGER
          Right:EXPR-NAME w T:TYPE-WORD
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-LONGINT
        Left:EXPR-NAME r T:TYPE-LONGINT
        Right:EXPR-ADD T:TYPE-LONGINT
          Left:EXPR-NAME c T:TYPE-CARDINAL
          Right:EXPR-NAME n T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-LONGINT
        Left:EXPR-NAME r T:TYPE-LONGINT
        Right:EXPR-ADD T:TYPE-LONGINT
          Left:EXPR-NAME n T:TYPE-INTEGER
          Right:EXPR-NAME c T:TYPE-CARDINAL
*)

// Two constants, one signed and one unsigned, make a signed type in
// either order (getTypeConversion).

Program Test;

Const
  w = 1234;
  n = -500;
  c = 100000;

Var
  r : LongInt;

Begin
  r := w + n;
  r := n + w;
  r := c + n;
  r := n + c;
End.
