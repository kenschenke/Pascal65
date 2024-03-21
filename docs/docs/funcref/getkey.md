# GetKey

Returns a keystroke from the keyboard buffer.

## Declaration

    FUNCTION GetKey : Char;
    FUNCTION GetKeyNoWait : Char;

## Description

*GetKey* returns a keystroke from the keyboard. If no keystroke is currently
in the buffer it will wait for a key press. *GetKeyNoWait* will return a keystroke
from the keyboard buffer or *Chr(0)* if no keystroke is currently in the buffer.

## Example ##

```
Program example;

Var
    ch : Char;

Begin
    ch := GetKey;
End.
```
