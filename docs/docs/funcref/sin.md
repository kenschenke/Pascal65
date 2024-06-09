# Sin

Returns the sine of the input.

## Declaration

    Function Sin(num : real) : real;

## Description

*Sin* returns the sine of the input. The function expects the input to
be the angle in radians. The output is between -1.0 and 1.0.

## Example ##

```
Program example;

Var
    d : Integer = 220;  // degrees
    r : Real;  // radians

Begin
    r := d * (3.14159 / 180.0);  // convert degrees to radians
    writeln('The sine of ', d, ' is ', Sin(r):0:4);
End.
```
