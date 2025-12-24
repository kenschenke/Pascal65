(* Test 14 - Unit
D:DECL-TYPE test
  T:TYPE-UNIT
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE publicvar
      T:TYPE-STRING-VAR
    D:DECL-TYPE publicproc
      T:TYPE-PROCEDURE
        param: i
          T:TYPE-INTEGER
    D:DECL-TYPE publicfunc
      T:TYPE-FUNCTION
        return: TYPE-REAL
        param: a
          T:TYPE-BOOLEAN
    D:DECL-VARIABLE privatevar
      T:TYPE-INTEGER
    D:DECL-TYPE publicproc
      T:TYPE-PROCEDURE
        param: i
          T:TYPE-INTEGER
      S:STMT-BLOCK
        D:DECL-VARIABLE p
          T:TYPE-BOOLEAN
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL In Public Proc
              EXPR-NAME i
    D:DECL-TYPE publicfunc
      T:TYPE-FUNCTION
        return: TYPE-REAL
        param: a
          T:TYPE-BOOLEAN
      S:STMT-BLOCK
        D:DECL-VARIABLE s
          T:TYPE-STRING-VAR
        D:DECL-VARIABLE publicfunc
          T:TYPE-REAL
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL In Public Func
              EXPR-NAME s
    D:DECL-TYPE privateproc
      T:TYPE-PROCEDURE
        param: b
          T:TYPE-WORD
      S:STMT-BLOCK
        D:DECL-VARIABLE c
          T:TYPE-CARDINAL
        D:DECL-VARIABLE d
          T:TYPE-CARDINAL
        S:STMT-EXPR
          E:EXPR-CALL
            Left:EXPR-NAME writeln
            Right:EXPR-ARG
              EXPR-STRING-LITERAL In Private Proc
              EXPR-NAME c
*)

Unit Test;

Interface

Var
  PublicVar : String;

Procedure PublicProc(i : Integer);
Function PublicFunc(a : Boolean) : Real;

Implementation

Var
  PrivateVar : Integer;

Procedure PublicProc(i : Integer);
Var
  p : Boolean;
Begin
  Writeln('In Public Proc', i);
End;

Function PublicFunc(a : Boolean ) : Real;
Var
  s : String;
Begin
  Writeln('In Public Func', s);
End;

Procedure PrivateProc(b : Word);
Var
  c, d : Cardinal;
Begin
  Writeln('In Private Proc', c);
End;

End.
