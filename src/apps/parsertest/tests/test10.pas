(* Test 10 - Records
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
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
    D:DECL-VARIABLE rec
      T:TYPE-DECLARED myrec
    D:DECL-VARIABLE otherrec
      T:TYPE-RECORD
        D:DECL-TYPE a
          T:TYPE-INTEGER
        D:DECL-TYPE s
          T:TYPE-STRING-VAR
        D:DECL-TYPE rec
          T:TYPE-DECLARED myrec
        D:DECL-TYPE alsorec
          T:TYPE-RECORD
            D:DECL-TYPE m
              T:TYPE-INTEGER
            D:DECL-TYPE n
              T:TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-FIELD
          Left:EXPR-NAME rec
          Right:EXPR-NAME i
        Right:EXPR-BYTE-LITERAL 8
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-FIELD
          Left:EXPR-NAME rec
          Right:EXPR-NAME j
        Right:EXPR-FIELD
          Left:EXPR-NAME otherrec
          Right:EXPR-NAME a
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-FIELD
          Left:EXPR-NAME otherrec
          Right:EXPR-NAME s
        Right:EXPR-STRING-LITERAL Hello, World
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-FIELD
          Left:EXPR-FIELD
            Left:EXPR-NAME otherrec
            Right:EXPR-NAME rec
          Right:EXPR-NAME r
        Right:EXPR-REAL-LITERAL 3.14159
*)

Program Test;

Type
  MyRec = Record
    i, j : Integer;
    r : Real;
    SubRec : Record
      x, y : Integer;
    End;
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
  rec.i := 8;
  rec.j := otherRec.a;
  otherRec.s := 'Hello, World';
  otherRec.rec.r := 3.14159;
End.
