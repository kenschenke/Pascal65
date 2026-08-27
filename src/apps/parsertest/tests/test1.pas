(* Test 1 - Scalar Variable Declarations
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE a
      T:TYPE-SHORTINT
    D:DECL-VARIABLE ch
      T:TYPE-CHARACTER
    D:DECL-VARIABLE card
      T:TYPE-CARDINAL
    D:DECL-VARIABLE b
      T:TYPE-BYTE
    D:DECL-VARIABLE bool
      T:TYPE-BOOLEAN
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-VARIABLE j
      T:TYPE-INTEGER
    D:DECL-VARIABLE r
      T:TYPE-REAL
    D:DECL-VARIABLE w
      T:TYPE-WORD
    D:DECL-VARIABLE str
      T:TYPE-STRING-VAR
    D:DECL-VARIABLE fi
      T:TYPE-FILE
        T:TYPE-INTEGER
    D:DECL-VARIABLE ft
      T:TYPE-TEXT
*)

Program Test;

Var
    a : ShortInt;
    ch : Char;
    card : Cardinal;
    b : Byte;
    bool : Boolean;
    i, j : Integer;
    r : Real;
    w : Word;
    str : String;
    fi : File Of Integer;
    ft : Text;

Begin
End.
