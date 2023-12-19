# Peek

Returns the byte value from a memory location.

## Declaration

    FUNCTION Peek(address : word) : byte;

## Description

*Peek* returns the byte value from a supplied memory location.

## Example ##

```
PROGRAM example;

BEGIN
    writeln('The border color is ', peek($d020));
END.
```
