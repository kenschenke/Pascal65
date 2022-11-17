# Odd

Returns a boolean value to indicate whether the input is odd or even.

## Declaration

    FUNCTION Odd(num : integer) : boolean;

## Description

*Odd* returns *true* if *num* is odd, or *false* otherwise.

## Example ##

```
PROGRAM example;

BEGIN
    IF Odd(3) THEN
        writeln('Input is odd')
    ELSE
        writeln('Input is even');
END.
```
