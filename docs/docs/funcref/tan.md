# Tan

Returns the tangent of the input.

## Declaration

    Function Tan(num : real) : real;

## Description

*Tan* returns the tangest of the input. The function expects the input to
be the angle in radians. The output is between -1.0 and 1.0.

## Example ##

```
Program example;

Var
    d : Integer = 220;  // degrees
    r : Real;  // radians

Begin
    r := d * (3.14159 / 180.0);  // convert degrees to radians
    writeln('The tangent of ', d, ' is ', Tan(r):0:4);
End.
```
