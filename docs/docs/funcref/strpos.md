# StrPos

Returns the position of a substring within a string.

## Declaration

    Function StrPos(str, sub : String; offset : Byte) : Byte;

## Description

*StrPos* returns the position of a substring within a string, starting at
a specified position. 0 is returned if the substring does not exist in
the string starting at the offset.

## Example ##

```
Program example;

Begin
    Writeln('Position of World within Hello World: ', StrPos('Hello World', 'World', 1));
End.
```
