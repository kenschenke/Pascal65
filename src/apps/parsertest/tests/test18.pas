(* Test 18 - Routine parameters, return types and forward declarations
D:DECL-TYPE test18
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE myint
      T:TYPE-INTEGER
    D:DECL-TYPE fwd
      T:TYPE-PROCEDURE
        param: a
          T:TYPE-INTEGER
    D:DECL-TYPE p1
      T:TYPE-PROCEDURE
        param: c
          T:TYPE-CHARACTER
        param: b
          T:TYPE-BYTE
        param: s
          T:TYPE-SHORTINT
        param: w
          T:TYPE-WORD
        param: i
          T:TYPE-INTEGER
        param: cd
          T:TYPE-CARDINAL
        param: l
          T:TYPE-LONGINT
        param: r
          T:TYPE-REAL
        param: bo
          T:TYPE-BOOLEAN
        param: st
          T:TYPE-STRING-VAR
      S:STMT-BLOCK
    D:DECL-TYPE p2
      T:TYPE-PROCEDURE
        param: f
          T:TYPE-FILE
          flags: TYPE-FLAG-ISBYREF
        param: t
          T:TYPE-TEXT
          flags: TYPE-FLAG-ISBYREF
        param: m
          T:TYPE-DECLARED myint
        param: a
          T:TYPE-ARRAY DYNAMIC OF TYPE-INTEGER
        param: p
          T:TYPE-POINTER
            T:TYPE-INTEGER
        param: q
          T:TYPE-POINTER
            T:TYPE-DECLARED myint
          flags: TYPE-FLAG-ISBYREF
      S:STMT-BLOCK
    D:DECL-TYPE f1
      T:TYPE-FUNCTION
        return: TYPE-BYTE
      S:STMT-BLOCK
        D:DECL-VARIABLE f1
          T:TYPE-BYTE
    D:DECL-TYPE f2
      T:TYPE-FUNCTION
        return: TYPE-SHORTINT
      S:STMT-BLOCK
        D:DECL-VARIABLE f2
          T:TYPE-SHORTINT
    D:DECL-TYPE f3
      T:TYPE-FUNCTION
        return: TYPE-BOOLEAN
      S:STMT-BLOCK
        D:DECL-VARIABLE f3
          T:TYPE-BOOLEAN
    D:DECL-TYPE f4
      T:TYPE-FUNCTION
        return: TYPE-CHARACTER
      S:STMT-BLOCK
        D:DECL-VARIABLE f4
          T:TYPE-CHARACTER
    D:DECL-TYPE f5
      T:TYPE-FUNCTION
        return: TYPE-WORD
      S:STMT-BLOCK
        D:DECL-VARIABLE f5
          T:TYPE-WORD
    D:DECL-TYPE f6
      T:TYPE-FUNCTION
        return: TYPE-INTEGER
      S:STMT-BLOCK
        D:DECL-VARIABLE f6
          T:TYPE-INTEGER
    D:DECL-TYPE f7
      T:TYPE-FUNCTION
        return: TYPE-LONGINT
      S:STMT-BLOCK
        D:DECL-VARIABLE f7
          T:TYPE-LONGINT
    D:DECL-TYPE f8
      T:TYPE-FUNCTION
        return: TYPE-CARDINAL
      S:STMT-BLOCK
        D:DECL-VARIABLE f8
          T:TYPE-CARDINAL
    D:DECL-TYPE f9
      T:TYPE-FUNCTION
        return: TYPE-REAL
      S:STMT-BLOCK
        D:DECL-VARIABLE f9
          T:TYPE-REAL
    D:DECL-TYPE f10
      T:TYPE-FUNCTION
        return: TYPE-STRING-VAR
      S:STMT-BLOCK
        D:DECL-VARIABLE f10
          T:TYPE-STRING-VAR
    D:DECL-TYPE f11
      T:TYPE-FUNCTION
        return: TYPE-DECLARED
      S:STMT-BLOCK
        D:DECL-VARIABLE f11
          T:TYPE-DECLARED myint
    D:DECL-TYPE f12
      T:TYPE-FUNCTION
        return: TYPE-POINTER
      S:STMT-BLOCK
        D:DECL-VARIABLE f12
          T:TYPE-POINTER
            T:TYPE-INTEGER
    D:DECL-TYPE fwd
      T:TYPE-PROCEDURE
        param: a
          T:TYPE-INTEGER
      S:STMT-BLOCK
*)

Program Test18;

Type
    MyInt = Integer;

Procedure Fwd(a : Integer); Forward;

Procedure P1(c : Char; b : Byte; s : ShortInt; w : Word; i : Integer;
    cd : Cardinal; l : LongInt; r : Real; bo : Boolean; st : String);
Begin
End;

Procedure P2(Var f : File; Var t : Text; m : MyInt;
    a : Array Of Integer; p : ^Integer; Var q : ^MyInt);
Begin
End;

Function F1 : Byte; Begin End;
Function F2 : ShortInt; Begin End;
Function F3 : Boolean; Begin End;
Function F4 : Char; Begin End;
Function F5 : Word; Begin End;
Function F6 : Integer; Begin End;
Function F7 : LongInt; Begin End;
Function F8 : Cardinal; Begin End;
Function F9 : Real; Begin End;
Function F10 : String; Begin End;
Function F11 : MyInt; Begin End;
Function F12 : ^Integer; Begin End;

Procedure Fwd(a : Integer);
Begin
End;

Begin
End.
