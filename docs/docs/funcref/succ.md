# Succ

Returns the next value for the input.

## Declaration

    FUNCTION Succ(ch : char) : char;
    FUNCTION Succ(num : byte) : byte;
    FUNCTION Succ(num : shortint) : shortint;
    FUNCTION Succ(num : word) : word;
    FUNCTION Succ(num : integer) : integer;
    FUNCTION Succ(num : cardinal) : cardinal;
    FUNCTION Succ(num : longint) : longint;

## Description

*Succ* returns the next value for the input. For an integer, the next value is returned. For a character, the next value.

## Example ##

```
PROGRAM example;

VAR
    i : integer;

BEGIN
    i := 12345;
    writeln('The next value of ', i, ' is ', Succ(i));
END.
```
