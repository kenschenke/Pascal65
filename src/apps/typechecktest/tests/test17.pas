(* Test 17 - Forward Declarations
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
    D:DECL-TYPE myrec
      T:TYPE-RECORD
        D:DECL-TYPE a
          T:TYPE-INTEGER
        D:DECL-TYPE b
          T:TYPE-INTEGER
        D:DECL-TYPE c
          T:TYPE-INTEGER
        D:DECL-TYPE num
          T:TYPE-REAL
    D:DECL-TYPE myarray
      T:TYPE-ARRAY  1.. 5 OF TYPE-INTEGER
    D:DECL-TYPE scalarproctype
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: i
            T:TYPE-INTEGER
          param: j
            T:TYPE-INTEGER
          param: b
            T:TYPE-BOOLEAN
          param: r
            T:TYPE-REAL
    D:DECL-TYPE scalarfunctype
      T:TYPE-ROUTINE-POINTER
        T:TYPE-FUNCTION
          return: TYPE-REAL
          param: i
            T:TYPE-INTEGER
    D:DECL-TYPE colorproctype
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: c
            T:TYPE-DECLARED colors
    D:DECL-TYPE colorfunctype
      T:TYPE-ROUTINE-POINTER
        T:TYPE-FUNCTION
          return: TYPE-DECLARED
          param: c
            T:TYPE-DECLARED colors
    D:DECL-TYPE recproctype
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: rec
            T:TYPE-DECLARED myrec
            flags: TYPE-FLAG-ISBYREF
    D:DECL-TYPE arrayproctype
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: arr
            T:TYPE-DECLARED myarray
    D:DECL-VARIABLE sp
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: i
            T:TYPE-INTEGER
          param: j
            T:TYPE-INTEGER
          param: b
            T:TYPE-BOOLEAN
          param: r
            T:TYPE-REAL
    D:DECL-VARIABLE sf
      T:TYPE-ROUTINE-POINTER
        T:TYPE-FUNCTION
          return: TYPE-REAL
          param: i
            T:TYPE-INTEGER
    D:DECL-VARIABLE cp
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: c
            T:TYPE-DECLARED colors
    D:DECL-VARIABLE cf
      T:TYPE-ROUTINE-POINTER
        T:TYPE-FUNCTION
          return: TYPE-DECLARED
          param: c
            T:TYPE-DECLARED colors
    D:DECL-VARIABLE rp
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: rec
            T:TYPE-DECLARED myrec
            flags: , TYPE-FLAG-ISBYREF
    D:DECL-VARIABLE ap
      T:TYPE-ROUTINE-POINTER
        T:TYPE-PROCEDURE
          param: arr
            T:TYPE-DECLARED myarray
    D:DECL-TYPE scalarproc
      T:TYPE-PROCEDURE
        param: i
          T:TYPE-INTEGER
        param: j
          T:TYPE-INTEGER
        param: b
          T:TYPE-BOOLEAN
        param: r
          T:TYPE-REAL
    D:DECL-TYPE scalarfunc
      T:TYPE-FUNCTION
        return: TYPE-REAL
        param: i
          T:TYPE-INTEGER
    D:DECL-TYPE colorproc
      T:TYPE-PROCEDURE
        param: c
          T:TYPE-DECLARED colors
    D:DECL-TYPE colorfunc
      T:TYPE-FUNCTION
        return: TYPE-DECLARED
        param: c
          T:TYPE-DECLARED colors
    D:DECL-TYPE recproc
      T:TYPE-PROCEDURE
        param: rec
          T:TYPE-DECLARED myrec
          flags: TYPE-FLAG-ISBYREF
    D:DECL-TYPE arrayproc
      T:TYPE-PROCEDURE
        param: arr
          T:TYPE-DECLARED myarray
    D:DECL-TYPE scalarproc
      T:TYPE-PROCEDURE
        param: i
          T:TYPE-INTEGER
        param: j
          T:TYPE-INTEGER
        param: b
          T:TYPE-BOOLEAN
        param: r
          T:TYPE-REAL
      S:STMT-BLOCK
    D:DECL-TYPE scalarfunc
      T:TYPE-FUNCTION
        return: TYPE-REAL
        param: i
          T:TYPE-INTEGER
      S:STMT-BLOCK
        D:DECL-VARIABLE scalarfunc
          T:TYPE-REAL
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
    D:DECL-TYPE recproc
      T:TYPE-PROCEDURE
        param: rec
          T:TYPE-DECLARED myrec
          flags: , TYPE-FLAG-ISBYREF
      S:STMT-BLOCK
    D:DECL-TYPE arrayproc
      T:TYPE-PROCEDURE
        param: arr
          T:TYPE-DECLARED myarray
      S:STMT-BLOCK
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-VOID
        Left:EXPR-NAME sp T:TYPE-ROUTINE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ROUTINE-ADDRESS
          Left:EXPR-NAME scalarproc T:TYPE-PROCEDURE
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-VOID
        Left:EXPR-NAME sf T:TYPE-ROUTINE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ROUTINE-ADDRESS
          Left:EXPR-NAME scalarfunc T:TYPE-FUNCTION
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-VOID
        Left:EXPR-NAME cp T:TYPE-ROUTINE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ROUTINE-ADDRESS
          Left:EXPR-NAME colorproc T:TYPE-PROCEDURE
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-VOID
        Left:EXPR-NAME cf T:TYPE-ROUTINE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ROUTINE-ADDRESS
          Left:EXPR-NAME colorfunc T:TYPE-FUNCTION
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-VOID
        Left:EXPR-NAME rp T:TYPE-ROUTINE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ROUTINE-ADDRESS
          Left:EXPR-NAME recproc T:TYPE-PROCEDURE
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-VOID
        Left:EXPR-NAME ap T:TYPE-ROUTINE-POINTER
        Right:EXPR-ADDRESS-OF T:TYPE-ROUTINE-ADDRESS
          Left:EXPR-NAME arrayproc T:TYPE-PROCEDURE
*)

Program Test;

Type
    Colors = (Red, Green, Blue);
    MyRec = Record
      a, b, c : Integer;
      num : Real;
    End;
    MyArray = Array[1..5] Of Integer;
    ScalarProcType = Procedure(i, j : Integer; b : Boolean; r : Real);
    ScalarFuncType = Function(i : Integer) : Real;
    ColorProcType = Procedure(c : Colors);
    ColorFuncType = Function(c : Colors) : Colors;
    RecProcType = Procedure(Var rec : MyRec);
    ArrayProcType = Procedure(arr : MyArray);

Var
    sp : ScalarProcType;
    sf : ScalarFuncType;
    cp : ColorProcType;
    cf : ColorFuncType;
    rp : RecProcType;
    ap : ArrayProcType;

Procedure ScalarProc(i, j : Integer; b : Boolean; r : Real); Forward;
Function ScalarFunc(i : Integer) : Real; Forward;
Procedure ColorProc(c : Colors); Forward;
Function ColorFunc(c : Colors) : Colors; Forward;
Procedure RecProc(Var rec : MyRec); Forward;
Procedure ArrayProc(arr : MyArray); Forward;

Procedure ScalarProc(i, j : Integer; b : Boolean; r : Real);
Begin
End;

Function ScalarFunc(i : Integer) : Real;
Begin
End;

Procedure ColorProc(c : Colors);
Begin
End;

Function ColorFunc(c : Colors) : Colors;
Begin
End;

Procedure RecProc(Var rec : MyRec);
Begin
End;

Procedure ArrayProc(arr : MyArray);
Begin
End;

Begin
  sp := @ScalarProc;
  sf := @ScalarFunc;
  cp := @ColorProc;
  cf := @ColorFunc;
  rp := @RecProc;
  ap := @ArrayProc;
End.
