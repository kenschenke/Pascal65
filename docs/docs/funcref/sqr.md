# Sqr

Returns the square of the input.

## Declaration

    FUNCTION Sqr(num : longint) : longint;
    FUNCTION Sqr(num : real) : real;

## Description

*Sqr* returns the square of the input.

## Example ##

```
PROGRAM example;

VAR
    i : longint;

BEGIN
    i := 5;
    writeln('The square of ', i, ' is ', Sqr(i));
END.
```
