(* Test 19 - Constants, subranges, expressions and case labels
D:DECL-TYPE test19
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-USES screen
      T:TYPE-UNIT
    D:DECL-CONST c1
      T:TYPE-BOOLEAN
      E:EXPR-BOOLEAN-LITERAL true
    D:DECL-CONST c2
      T:TYPE-BOOLEAN
      E:EXPR-BOOLEAN-LITERAL false
    D:DECL-CONST c3
      T:TYPE-ADDRESS
      E:EXPR-WORD-LITERAL 0
    D:DECL-TYPE myint
      T:TYPE-INTEGER
    D:DECL-TYPE range
      T:TYPE-ENUMERATION
        D:DECL-TYPE one
          E:EXPR-WORD-LITERAL 0
        D:DECL-TYPE two
          E:EXPR-WORD-LITERAL 1
        D:DECL-TYPE three
          E:EXPR-WORD-LITERAL 2
        D:DECL-TYPE four
          E:EXPR-WORD-LITERAL 3
    D:DECL-TYPE sub1
      T:TYPE-SUBRANGE
        min: two
        max: four
    D:DECL-TYPE sub2
      T:TYPE-SUBRANGE
        min: 3e8
        max: 7d0
    D:DECL-TYPE sub3
      T:TYPE-SUBRANGE
        min: 186a0
        max: 30d40
    D:DECL-TYPE sub4
      T:TYPE-SUBRANGE
        min: -5
        max: 5
    D:DECL-VARIABLE i
      T:TYPE-INTEGER
    D:DECL-VARIABLE r
      T:TYPE-REAL
    D:DECL-VARIABLE s
      T:TYPE-STRING-VAR
    D:DECL-VARIABLE p
      T:TYPE-POINTER
        T:TYPE-INTEGER
    D:DECL-VARIABLE a
      T:TYPE-ARRAY  1.. 3 OF TYPE-INTEGER
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-BYTE-LITERAL -5
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-NAME i
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME i
        Right:EXPR-ADD
          Left:EXPR-ADD
            Left:EXPR-ADD
              Left:EXPR-TYPE-CAST T:TYPE-SHORTINT
                Left:EXPR-NAME i
              Right:EXPR-TYPE-CAST T:TYPE-WORD
                Left:EXPR-NAME i
            Right:EXPR-TYPE-CAST T:TYPE-CARDINAL
              Left:EXPR-NAME i
          Right:EXPR-TYPE-CAST T:TYPE-LONGINT
            Left:EXPR-NAME i
    S:STMT-IF-ELSE
      E:EXPR-BOOLEAN-LITERAL false
      If True:
        S:STMT-EXPR
          E:EXPR-ASSIGN
            Left:EXPR-NAME i
            Right:EXPR-BYTE-LITERAL 1
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME p
        Right:EXPR-WORD-LITERAL 0
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME writeln
        Right:EXPR-ARG
          EXPR-NAME r
          EXPR-NAME i
    S:STMT-EXPR
      E:EXPR-ASSIGN
        Left:EXPR-NAME s
        Right:EXPR-CALL
          Left:EXPR-NAME writestr
          Right:EXPR-ARG
            EXPR-NAME i
            EXPR-NAME r
    S:STMT-CASE
      E:EXPR-NAME i
      S:STMT-CASE-LABEL
        EXPR-BYTE-LITERAL ff
        Case Body:
          S:STMT-EXPR
            E:EXPR-ASSIGN
              Left:EXPR-NAME i
              Right:EXPR-BYTE-LITERAL 1
      S:STMT-CASE-LABEL
        EXPR-WORD-LITERAL fc18
        Case Body:
          S:STMT-EXPR
            E:EXPR-ASSIGN
              Left:EXPR-NAME i
              Right:EXPR-BYTE-LITERAL 2
      S:STMT-CASE-LABEL
        EXPR-DWORD-LITERAL fffe7960
        Case Body:
          S:STMT-EXPR
            E:EXPR-ASSIGN
              Left:EXPR-NAME i
              Right:EXPR-BYTE-LITERAL 3
      S:STMT-CASE-LABEL
        EXPR-BYTE-LITERAL 5
        Case Body:
          S:STMT-EXPR
            E:EXPR-ASSIGN
              Left:EXPR-NAME i
              Right:EXPR-BYTE-LITERAL 4
*)

Program Test19;

Uses Screen;;

Const
    c1 = True;
    c2 = False;;
    c3 = nil;

Type
    MyInt = Integer;;
    Range = (One, Two, Three, Four);
    Sub1 = Two..Four;
    Sub2 = +1000..2000;
    Sub3 = 100000..200000;
    Sub4 = -5..5;

Var
    i : Integer;;
    r : Real;
    s : String;
    p : ^Integer;
    a : Array[1..3] Of Integer = ();

Begin
    i := -5;
    i := -i;
    i := ShortInt(i) + Word(i) + Cardinal(i) + LongInt(i);
    If False Then i := 1;
    p := nil;
    Writeln(r:10:2, i:5);
    s := WriteStr(i:5, r:6:1);
    Case i Of
        -1: i := 1;
        -1000: i := 2;
        -100000: i := 3;
        +5: i := 4;
    End;
End.
