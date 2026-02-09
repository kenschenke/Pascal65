(* Test 9 - Strings
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE str
      T:TYPE-STRING-VAR
    D:DECL-VARIABLE ch
      T:TYPE-CHARACTER
    D:DECL-VARIABLE arr
      T:TYPE-ARRAY  1.. 5 OF TYPE-CHARACTER
    D:DECL-TYPE myproc
      T:TYPE-PROCEDURE
        param: s
          T:TYPE-STRING-VAR
      S:STMT-BLOCK
    D:DECL-TYPE myfunc
      T:TYPE-FUNCTION
        return: TYPE-STRING-VAR
        param: a
          T:TYPE-INTEGER
      S:STMT-BLOCK
        D:DECL-VARIABLE myfunc
          T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-STRING-LITERAL
        Left:EXPR-NAME str T:TYPE-STRING-VAR
        Right:EXPR-STRING-LITERAL Hello, World T:TYPE-STRING-LITERAL
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-CHARACTER
        Left:EXPR-NAME ch T:TYPE-CHARACTER
        Right:EXPR-SUBSCRIPT T:TYPE-CHARACTER
          Left:EXPR-NAME str T:TYPE-STRING-VAR
          Right:EXPR-BYTE-LITERAL 5 T:TYPE-SHORTINT
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-CHARACTER
        Left:EXPR-NAME str T:TYPE-STRING-VAR
        Right:EXPR-CHARACTER-LITERAL 'a' T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-CHARACTER
        Left:EXPR-NAME str T:TYPE-STRING-VAR
        Right:EXPR-NAME ch T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME myproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME str T:TYPE-STRING-VAR
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME myproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME arr T:TYPE-ARRAY
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME myproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-CHARACTER-LITERAL 'b' T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-CALL T:TYPE-VOID
        Left:EXPR-NAME myproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-STRING-LITERAL abc123 T:TYPE-STRING-LITERAL
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-STRING-VAR
        Left:EXPR-NAME str T:TYPE-STRING-VAR
        Right:EXPR-CALL T:TYPE-STRING-VAR
          Left:EXPR-NAME myfunc T:TYPE-FUNCTION
          Right:EXPR-ARG
            EXPR-WORD-LITERAL 3039 T:TYPE-INTEGER
*)

Program Test;

Var
  str : String;
  ch : Char;
  arr : Array[1..5] Of Char;

Procedure MyProc(s : String);
Begin
End;

Function MyFunc(a : Integer) : String;
Begin
End;

Begin
  str := 'Hello, World';
  ch := str[5];
  str := 'a';
  str := ch;
  MyProc(str);
  MyProc(arr);
  MyProc('b');
  MyProc('abc123');
  str := MyFunc(12345);
End.
