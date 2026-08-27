(* Test 8 - Pointers
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
    D:DECL-TYPE myrec
      T:TYPE-RECORD
        D:DECL-TYPE a
          T:TYPE-INTEGER
        D:DECL-TYPE b
          T:TYPE-INTEGER
        D:DECL-TYPE r
          T:TYPE-REAL
    D:DECL-TYPE arraytype
      T:TYPE-ARRAY  1.. 5 OF TYPE-INTEGER
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-VARIABLE arr
      T:TYPE-ARRAY  1.. 5 OF TYPE-INTEGER
    D:DECL-VARIABLE pi
      T:TYPE-POINTER
        T:TYPE-INTEGER
    D:DECL-VARIABLE pr
      T:TYPE-POINTER
        T:TYPE-DECLARED myrec
    D:DECL-VARIABLE pp
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: num
            T:TYPE-INTEGER
    D:DECL-VARIABLE rec
      T:TYPE-RECORD
        D:DECL-TYPE a
          T:TYPE-INTEGER
        D:DECL-TYPE b
          T:TYPE-INTEGER
        D:DECL-TYPE r
          T:TYPE-REAL
    D:DECL-VARIABLE pa
      T:TYPE-POINTER
        T:TYPE-DECLARED arraytype
    D:DECL-VARIABLE pf
      T:TYPE-ROUTINE-POINTER
        T:TYPE-FUNCTION
          return: TYPE-CHARACTER
          param: a
            T:TYPE-BOOLEAN
    D:DECL-VARIABLE c
      T:TYPE-CHARACTER
    D:DECL-TYPE myproc
      T:TYPE-PROCEDURE
        param: abc
          T:TYPE-INTEGER
      S:STMT-BLOCK
    D:DECL-TYPE myfunc
      T:TYPE-FUNCTION
        return: TYPE-CHARACTER
        param: a
          T:TYPE-BOOLEAN
      S:STMT-BLOCK
        D:DECL-VARIABLE myfunc
          T:TYPE-CHARACTER
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME pi T:TYPE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ADDRESS
          Left:EXPR-NAME i T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-POINTER T:TYPE-INTEGER
          Left:EXPR-NAME pi T:TYPE-POINTER
        Right:EXPR-WORD-LITERAL 3039 T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME pr T:TYPE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ADDRESS
          Left:EXPR-NAME rec T:TYPE-RECORD
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-FIELD T:TYPE-INTEGER
          Left:EXPR-POINTER T:TYPE-DECLARED
            Left:EXPR-NAME pr T:TYPE-POINTER
          Right:EXPR-NAME a T:TYPE-INTEGER
        Right:EXPR-BYTE-LITERAL 7b T:TYPE-SHORTINT
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME pi T:TYPE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ADDRESS
          Left:EXPR-SUBSCRIPT T:TYPE-INTEGER
            Left:EXPR-NAME arr T:TYPE-ARRAY
            Right:EXPR-BYTE-LITERAL 1 T:TYPE-SHORTINT
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME pp T:TYPE-ROUTINE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ROUTINE-ADDRESS
          Left:EXPR-NAME myproc T:TYPE-PROCEDURE
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME pp T:TYPE-ROUTINE-POINTER
        Right:EXPR-ARG
          EXPR-WORD-LITERAL 1c8 T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME pa T:TYPE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ADDRESS
          Left:EXPR-NAME arr T:TYPE-ARRAY
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-SUBSCRIPT T:TYPE-INTEGER
          Left:EXPR-POINTER T:TYPE-DECLARED
            Left:EXPR-NAME pa T:TYPE-POINTER
          Right:EXPR-BYTE-LITERAL 5 T:TYPE-SHORTINT
        Right:EXPR-BYTE-LITERAL ea T:TYPE-BYTE
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-SUBSCRIPT T:TYPE-INTEGER
          Left:EXPR-POINTER T:TYPE-DECLARED
            Left:EXPR-NAME pa T:TYPE-POINTER
          Right:EXPR-BYTE-LITERAL 2 T:TYPE-SHORTINT
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME pf T:TYPE-ROUTINE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ROUTINE-ADDRESS
          Left:EXPR-NAME myfunc T:TYPE-FUNCTION
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-CHARACTER
        Left:EXPR-NAME c T:TYPE-CHARACTER
        Right:EXPR-CALL T:TYPE-CHARACTER
          Left:EXPR-NAME pf T:TYPE-ROUTINE-POINTER
          Right:EXPR-ARG
            EXPR-BOOLEAN-LITERAL true T:TYPE-BOOLEAN
*)

Program Test;

Type
  ProcType = Procedure(num : Integer);
  FuncType = Function(a : Boolean) : Char;
  MyRec = Record
    a, b : Integer;
    r : Real;
  End;
  ArrayType = Array[1..5] Of Integer;

Var
  i : Integer;
  arr : ArrayType;
  pi : ^Integer;
  pr : ^MyRec;
  pp : ProcType;
  rec : MyRec;
  pa : ^ArrayType;
  pf : FuncType;
  c : Char;

Procedure MyProc(abc : Integer);
Begin
End;

Function MyFunc(a : Boolean) : Char;
Begin
End;

Begin
  pi := @i;
  pi^ := 12345;
  pr := @rec;
  pr^.a := 123;
  pi := @arr[1];
  pp := @MyProc;
  pp(456);
  pa := @arr;
  pa^[5] := 234;
  i := pa^[2];
  pf := @MyFunc;
  c := pf(true);
End.
