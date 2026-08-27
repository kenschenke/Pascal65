(* Test 11 - Functions and Procedures
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE myproc
      T:TYPE-PROCEDURE
        param: a
          T:TYPE-INTEGER
        param: b
          T:TYPE-INTEGER
        param: r
          T:TYPE-REAL
          flags: TYPE-FLAG-ISBYREF
        param: x
          T:TYPE-STRING-VAR
      S:STMT-BLOCK
        D:DECL-VARIABLE n
          T:TYPE-INTEGER
        D:DECL-VARIABLE m
          T:TYPE-INTEGER
        D:DECL-VARIABLE k
          T:TYPE-BOOLEAN
        D:DECL-TYPE innerproc
          T:TYPE-PROCEDURE
            param: o
              T:TYPE-INTEGER
            param: p
              T:TYPE-INTEGER
          S:STMT-BLOCK
            D:DECL-VARIABLE x
              T:TYPE-WORD
            S:STMT-EXPR
              E:EXPR-ASSIGN
                Left:EXPR-NAME x
                Right:EXPR-ADD
                  Left:EXPR-NAME x
                  Right:EXPR-BYTE-LITERAL 1
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL x = 
              EXPR-NAME x
    D:DECL-TYPE myfunc
      T:TYPE-FUNCTION
        return: TYPE-STRING-VAR
        param: b
          T:TYPE-BOOLEAN
        param: j
          T:TYPE-INTEGER
      S:STMT-BLOCK
        D:DECL-VARIABLE r
          T:TYPE-REAL
        D:DECL-VARIABLE s
          T:TYPE-STRING-VAR
        D:DECL-VARIABLE t
          T:TYPE-STRING-VAR
        D:DECL-VARIABLE myfunc
          T:TYPE-STRING-VAR
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME write
            Right:EXPR-ARG
              EXPR-STRING-LITERAL b = 
              EXPR-NAME b
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME myproc
        Right:EXPR-ARG
          EXPR-BYTE-LITERAL 7b
          EXPR-WORD-LITERAL 1c8
          EXPR-REAL-LITERAL 3.14159
          EXPR-STRING-LITERAL Hello, World
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME writeln
*)

Program Test;

Procedure MyProc(a, b : Integer; Var r : Real; x : String);
Var
  n, m : Integer;
  k : Boolean;

  Procedure InnerProc(o, p : Integer);
  Var
    x : Word;
  Begin
    x := x + 1;
  End;

Begin
  Writeln('x = ', x);
End;

Function MyFunc(b : Boolean; j : Integer) : String;
Var
  r : Real;
  s, t : String;
Begin
  Write('b = ', b);
End;

Begin
  MyProc(123, 456, 3.14159, 'Hello, World');
  Writeln;
End.
