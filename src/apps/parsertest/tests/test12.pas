(* Test 12 - Pointers
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE proctype
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: num
            T:TYPE-INTEGER
    D:DECL-TYPE functype
      T:TYPE-ROUTINE-POINTER
        T:TYPE-FUNCTION
          return: TYPE-CHARACTER
          param: a
            T:TYPE-BOOLEAN
    D:DECL-VARIABLE pi
      T:TYPE-POINTER
        T:TYPE-INTEGER
    D:DECL-VARIABLE pr
      T:TYPE-POINTER
        T:TYPE-DECLARED myrec
    D:DECL-VARIABLE pp
      T:TYPE-DECLARED proctype
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME pi
        Right:EXPR-ADDRESS-OF
          Left:EXPR-NAME i
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-POINTER
          Left:EXPR-NAME pi
        Right:EXPR-WORD-LITERAL 3039
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-FIELD
          Left:EXPR-POINTER
            Left:EXPR-NAME pr
          Right:EXPR-NAME a
        Right:EXPR-BYTE-LITERAL 7b
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME pi
        Right:EXPR-ADDRESS-OF
          Left:EXPR-SUBSCRIPT
            Left:EXPR-NAME arr
            Right:EXPR-BYTE-LITERAL 1
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-SUBSCRIPT
          Left:EXPR-POINTER
            Left:EXPR-NAME ptr
          Right:EXPR-BYTE-LITERAL 5
        Right:EXPR-BYTE-LITERAL ea
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME pp
        Right:EXPR-ADDRESS-OF
          Left:EXPR-NAME myproc
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME pp
        Right:EXPR-ARG
          EXPR-WORD-LITERAL 1c8
*)

Program Test;

Type
  ProcType = Procedure(num : Integer);
  FuncType = Function(a : Boolean) : Char;

Var
  pi : ^Integer;
  pr : ^MyRec;
  pp : ProcType;

Begin
  pi := @i;
  pi^ := 12345;
  pr^.a := 123;
  pi := @arr[1];
  ptr^[5] := 234;
  pp := @MyProc;
  pp(456);
End.
