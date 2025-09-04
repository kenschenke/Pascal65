Unit Time;

Interface

Type
    DateTime = Record
        hour, minute, second, month, day : Byte;
        year : Word;
    End;

Procedure GetDateTime(Var dt : DateTime);
Function GetTicks : Cardinal;
Procedure ResetTicks;

Implementation Library

End.
