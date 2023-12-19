# Abs

Returns the absolute value of the input.

## Declaration

    FUNCTION Abs(num : shortint) : shortint;
    FUNCTION Abs(num : integer) : integer;
    FUNCTION Abs(num : longint) : longint;
    FUNCTION Abs(num : real) : real;

## Description

*Abs* returns the absolute value of the input.

## Example ##

```
PROGRAM example;

VAR
    i : integer;

BEGIN
    i := -5;
    writeln('The absolute value of ', i, ' is ', Abs(i));
END.
```
