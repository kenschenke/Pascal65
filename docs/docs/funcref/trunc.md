# Trunc

Truncates a real number to an integer by dropping the fractional part.

## Declaration

    Function Trunc(value : real) : integer;

## Description

*Trunc* truncates the fractional part of a real number and returns it as an integer.

## Example

```
Program example;

Begin
    Writeln(Trunc(10.875));  // Writes 10
End.
```

## See Also

[Round](../round)
