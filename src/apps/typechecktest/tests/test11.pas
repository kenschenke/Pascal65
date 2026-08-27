(* Test 11 - Files
D:DECL-TYPE test
  T:TYPE-PROGRAM
  S:STMT-BLOCK
    D:DECL-USES system
      T:TYPE-UNIT
    D:DECL-VARIABLE ft
      T:TYPE-TEXT
    D:DECL-VARIABLE fh
      T:TYPE-FILE
        T:TYPE-INTEGER
    D:DECL-TYPE textproc
      T:TYPE-PROCEDURE
        param: f
          T:TYPE-TEXT
          flags: TYPE-FLAG-ISBYREF
      S:STMT-BLOCK
    D:DECL-TYPE fileproc
      T:TYPE-PROCEDURE
        param: f
          T:TYPE-FILE
          flags: TYPE-FLAG-ISBYREF
      S:STMT-BLOCK
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME textproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME ft T:TYPE-TEXT
    S:STMT-EXPR
      E:EXPR-CALL
        Left:EXPR-NAME fileproc T:TYPE-PROCEDURE
        Right:EXPR-ARG
          EXPR-NAME fh T:TYPE-FILE
*)

Program Test;

Var
  ft : Text;
  fh : File Of Integer;

Procedure TextProc(Var f : Text);
Begin
End;

Procedure FileProc(Var f : File);
Begin
End;

Begin
  TextProc(ft);
  FileProc(fh);
End.
