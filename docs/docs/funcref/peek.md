# Peek

Returns the value from a memory location.

## Declaration

    Function Peek(address : Cardinal) : Byte;
    Function PeekW(address : Cardinal) : Word;
    Function PeekL(address : Cardinal) : Cardinal;

## Description

*Peek* returns the byte value from a supplied memory location. The memory location can be
specified as a 16-bit or 24-bit value.

*PeekW* returns the word value from a supplied memory location.

*PeekL* returns the cardinal value from a supplied memory location.

## Example ##

```
PROGRAM example;

BEGIN
    writeln('The border color is ', peek($d020));
END.
```
