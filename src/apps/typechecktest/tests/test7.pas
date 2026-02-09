(* Test 7 - Records
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE mysubrec
      T:TYPE-RECORD
        D:DECL-TYPE a
          T:TYPE-BYTE
        D:DECL-TYPE b
          T:TYPE-BYTE
    D:DECL-TYPE myrec
      T:TYPE-RECORD
        D:DECL-TYPE i
          T:TYPE-INTEGER
        D:DECL-TYPE j
          T:TYPE-INTEGER
        D:DECL-TYPE r
          T:TYPE-REAL
        D:DECL-TYPE subrec
          T:TYPE-RECORD
            D:DECL-TYPE x
              T:TYPE-INTEGER
            D:DECL-TYPE y
              T:TYPE-INTEGER
        D:DECL-TYPE my
          T:TYPE-RECORD
            D:DECL-TYPE a
              T:TYPE-BYTE
            D:DECL-TYPE b
              T:TYPE-BYTE
    D:DECL-VARIABLE rec
      T:TYPE-RECORD
        D:DECL-TYPE i
          T:TYPE-INTEGER
        D:DECL-TYPE j
          T:TYPE-INTEGER
        D:DECL-TYPE r
          T:TYPE-REAL
        D:DECL-TYPE subrec
          T:TYPE-RECORD
            D:DECL-TYPE x
              T:TYPE-INTEGER
            D:DECL-TYPE y
              T:TYPE-INTEGER
        D:DECL-TYPE my
          T:TYPE-RECORD
            D:DECL-TYPE a
              T:TYPE-BYTE
            D:DECL-TYPE b
              T:TYPE-BYTE
    D:DECL-VARIABLE otherrec
      T:TYPE-RECORD
        D:DECL-TYPE a
          T:TYPE-INTEGER
        D:DECL-TYPE s
          T:TYPE-STRING-VAR
        D:DECL-TYPE rec
          T:TYPE-RECORD
            D:DECL-TYPE i
              T:TYPE-INTEGER
            D:DECL-TYPE j
              T:TYPE-INTEGER
            D:DECL-TYPE r
              T:TYPE-REAL
            D:DECL-TYPE subrec
              T:TYPE-RECORD
                D:DECL-TYPE x
                  T:TYPE-INTEGER
                D:DECL-TYPE y
                  T:TYPE-INTEGER
            D:DECL-TYPE my
              T:TYPE-RECORD
                D:DECL-TYPE a
                  T:TYPE-BYTE
                D:DECL-TYPE b
                  T:TYPE-BYTE
        D:DECL-TYPE alsorec
          T:TYPE-RECORD
            D:DECL-TYPE m
              T:TYPE-INTEGER
            D:DECL-TYPE n
              T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-FIELD T:TYPE-INTEGER
          Left:EXPR-NAME rec T:TYPE-DECLARED
          Right:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-WORD-LITERAL 3039 T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-REAL
        Left:EXPR-FIELD T:TYPE-REAL
          Left:EXPR-NAME rec T:TYPE-DECLARED
          Right:EXPR-NAME r T:TYPE-REAL
        Right:EXPR-REAL-LITERAL 3.14 T:TYPE-REAL
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-FIELD T:TYPE-INTEGER
          Left:EXPR-FIELD T:TYPE-RECORD
            Left:EXPR-NAME rec T:TYPE-DECLARED
            Right:EXPR-NAME subrec T:TYPE-RECORD
          Right:EXPR-NAME x T:TYPE-INTEGER
        Right:EXPR-WORD-LITERAL 5ba0 T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-BYTE
        Left:EXPR-FIELD T:TYPE-BYTE
          Left:EXPR-FIELD T:TYPE-DECLARED
            Left:EXPR-NAME rec T:TYPE-DECLARED
            Right:EXPR-NAME my T:TYPE-DECLARED
          Right:EXPR-NAME a T:TYPE-BYTE
        Right:EXPR-BYTE-LITERAL 7b T:TYPE-SHORTINT
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-FIELD T:TYPE-INTEGER
          Left:EXPR-NAME otherrec T:TYPE-RECORD
          Right:EXPR-NAME a T:TYPE-INTEGER
        Right:EXPR-WORD-LITERAL 10e1 T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-STRING-LITERAL
        Left:EXPR-FIELD T:TYPE-STRING-VAR
          Left:EXPR-NAME otherrec T:TYPE-RECORD
          Right:EXPR-NAME s T:TYPE-STRING-VAR
        Right:EXPR-STRING-LITERAL Hello, World T:TYPE-STRING-LITERAL
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-FIELD T:TYPE-INTEGER
          Left:EXPR-FIELD T:TYPE-DECLARED
            Left:EXPR-NAME otherrec T:TYPE-RECORD
            Right:EXPR-NAME rec T:TYPE-DECLARED
          Right:EXPR-NAME i T:TYPE-INTEGER
        Right:EXPR-WORD-LITERAL 7d84 T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN T:TYPE-INTEGER
        Left:EXPR-FIELD T:TYPE-INTEGER
          Left:EXPR-FIELD T:TYPE-RECORD
            Left:EXPR-NAME otherrec T:TYPE-RECORD
            Right:EXPR-NAME alsorec T:TYPE-RECORD
          Right:EXPR-NAME m T:TYPE-INTEGER
        Right:EXPR-WORD-LITERAL 5b8a T:TYPE-INTEGER
*)

Program Test;

Type
  MySubRec = Record
    a, b : Byte;
  End;
  MyRec = Record
    i, j : Integer;
    r : Real;
    SubRec : Record
      x, y : Integer;
    End;
    my : MySubRec;
  End;

Var
  rec : MyRec;
  otherRec : Record
    a : Integer;
    s : String;
    rec : MyRec;
    AlsoRec : Record
      m, n : Integer;
    End;
  End;

Begin
  rec.i := 12345;
  rec.r := 3.14;
  rec.subrec.x := 23456;
  rec.my.a := 123;
  otherRec.a := 4321;
  otherRec.s := 'Hello, World';
  otherRec.rec.i := 32132;
  otherRec.AlsoRec.m := 23434;
End.
