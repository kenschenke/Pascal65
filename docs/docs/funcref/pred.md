# Pred

Returns the previous value for the input.

## Declaration

    FUNCTION Pred(ch : char) : char;
    FUNCTION Pred(num : byte) : byte;
    FUNCTION Pred(num : shortint) : shortint;
    FUNCTION Pred(num : word) : word;
    FUNCTION Pred(num : integer) : integer;
    FUNCTION Pred(num : cardinal) : cardinal;
    FUNCTION Pred(num : longint) : longint;

## Description

*Pred* returns the previous value for the input. For an integer, the previous value is returned. For a character, the previous value.

## Example ##

```
PROGRAM example;

VAR
    i : integer;

BEGIN
    i := 12345;
    writeln('The previous value of ', i, ' is ', Pred(i));
END.
```
