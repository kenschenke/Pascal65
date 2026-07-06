(* Test 16 - Enumerations
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE colors
      T:TYPE-ENUMERATION
        D:DECL-TYPE red
          E:EXPR-WORD-LITERAL 0
        D:DECL-TYPE green
          E:EXPR-WORD-LITERAL 1
        D:DECL-TYPE blue
          E:EXPR-WORD-LITERAL 2
    D:DECL-TYPE colorprocptr
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: c
            T:TYPE-DECLARED colors
    D:DECL-VARIABLE color
      T:TYPE-ENUMERATION
        D:DECL-TYPE red
          E:EXPR-WORD-LITERAL 0
        D:DECL-TYPE green
          E:EXPR-WORD-LITERAL 1
        D:DECL-TYPE blue
          E:EXPR-WORD-LITERAL 2
    D:DECL-VARIABLE othercolor
      T:TYPE-ENUMERATION
        D:DECL-TYPE red
          E:EXPR-WORD-LITERAL 0
        D:DECL-TYPE green
          E:EXPR-WORD-LITERAL 1
        D:DECL-TYPE blue
          E:EXPR-WORD-LITERAL 2
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-VARIABLE cp
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: c
            T:TYPE-DECLARED colors
    D:DECL-TYPE colorproc
      T:TYPE-PROCEDURE
        param: c
          T:TYPE-DECLARED colors
      S:STMT-BLOCK
    D:DECL-TYPE colorfunc
      T:TYPE-FUNCTION
        return: TYPE-DECLARED
        param: c
          T:TYPE-DECLARED colors
      S:STMT-BLOCK
        D:DECL-VARIABLE colorfunc
          T:TYPE-ENUMERATION
            D:DECL-TYPE red
              E:EXPR-WORD-LITERAL 0
            D:DECL-TYPE green
              E:EXPR-WORD-LITERAL 1
            D:DECL-TYPE blue
              E:EXPR-WORD-LITERAL 2
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-VOID
        Left:EXPR-NAME color T:TYPE-DECLARED
        Right:EXPR-NAME green T:TYPE-ENUMERATION-VALUE
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-CALL T:TYPE-INTEGER
          Left:EXPR-NAME ord T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-NAME color T:TYPE-DECLARED
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-ENUMERATION
        Left:EXPR-NAME othercolor T:TYPE-DECLARED
        Right:EXPR-CALL T:TYPE-ENUMERATION
          Left:EXPR-NAME pred T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-NAME color T:TYPE-DECLARED
    S:STMT-IF-ELSE
      E:EXPR-NE T:TYPE-BOOLEAN
        Left:EXPR-NAME othercolor T:TYPE-DECLARED
        Right:EXPR-NAME red T:TYPE-ENUMERATION-VALUE
      If True:
        S:STMT-EXPR
          E:EXPR-ASSIGN T:TYPE-VOID
            Left:EXPR-NAME othercolor T:TYPE-DECLARED
            Right:EXPR-NAME red T:TYPE-ENUMERATION-VALUE
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME colorproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME color T:TYPE-DECLARED
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-ENUMERATION
        Left:EXPR-NAME othercolor T:TYPE-DECLARED
        Right:EXPR-CALL T:TYPE-DECLARED
          Left:EXPR-NAME colorfunc T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-NAME color T:TYPE-DECLARED
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME colorproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME green T:TYPE-ENUMERATION-VALUE
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-VOID
        Left:EXPR-NAME cp T:TYPE-ROUTINE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ROUTINE-ADDRESS
          Left:EXPR-NAME colorproc T:TYPE-PROCEDURE
*)

Program Test;

Type
    Colors = (Red, Green, Blue);
    ColorProcPtr = Procedure(c : Colors);

Var
    color, otherColor : Colors;
    i : Integer;
    cp : ColorProcPtr;

Procedure ColorProc(c : Colors);
Begin
End;

Function ColorFunc(c : Colors) : Colors;
Begin
End;

Begin
    color := Green;
    i := Ord(Color);
    otherColor := Pred(color);
    If otherColor <> Red Then otherColor := Red;

    ColorProc(color);
    otherColor := ColorFunc(color);
    ColorProc(Green);

    cp := @ColorProc;
End.
