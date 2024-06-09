# Cos

Returns the cosine of the input.

## Declaration

    Function Cos(num : real) : real;

## Description

*Cos* returns the cosine of the input. The function expects the input to
be the angle in radians. The output is between -1.0 and 1.0.

## Example ##

```
Program example;

Var
    d : Integer = 220;  // degrees
    r : Real;  // radians

Begin
    r := d * (3.14159 / 180.0);  // convert degrees to radians
    writeln('The cosine of ', d, ' is ', Cos(r):0:4);
End.
```
