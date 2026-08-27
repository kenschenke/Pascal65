(* Test 3 - Type Definitions
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-TYPE mynumber
      T:TYPE-INTEGER
    D:DECL-TYPE myarray
      T:TYPE-ARRAY  1.. 5 OF TYPE-INTEGER
    D:DECL-TYPE myrecord
      T:TYPE-RECORD
        D:DECL-TYPE i
          T:TYPE-INTEGER
        D:DECL-TYPE r
          T:TYPE-REAL
    D:DECL-TYPE myenum
      T:TYPE-ENUMERATION
        D:DECL-TYPE one
          E:EXPR-WORD-LITERAL 0
        D:DECL-TYPE two
          E:EXPR-WORD-LITERAL 1
        D:DECL-TYPE three
          E:EXPR-WORD-LITERAL 2
        D:DECL-TYPE four
          E:EXPR-WORD-LITERAL 3
        D:DECL-TYPE five
          E:EXPR-WORD-LITERAL 4
    D:DECL-TYPE agerange
      T:TYPE-SUBRANGE
        min: 2
        max: 63
*)

Program Test;

Type
  MyNumber = Integer;
  MyArray = Array[1..5] Of Integer;
  MyRecord = Record
    i : Integer;
    r : Real;
  End;
  MyEnum = (One, Two, Three, Four, Five);
  AgeRange = 2..99;

Begin
End.
