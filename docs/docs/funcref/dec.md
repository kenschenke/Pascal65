# Dec

Decrements a variable.

!!! warning

    Due to technical limitations the Dec procedure is currently disabled.
    A workaround is under development.

## Declaration

    Procedure Dec(num);
    Procedure Dec(num, increment);

## Description

*Dec* decrements the variable passed in the first parameter. If a
second parameter is provided, the variable is decremented by that amount.

The *Dec* procedure supports all integer types (signed and unsigned),
enumeration types, and character. If the second parameter is present
it must be an integer (any size).

## Example ##

```
PROGRAM example;

VAR
    i : integer;

BEGIN
    i := 10;
    Dec(i);  // i is now 9
    Dec(i, 2); // i is now 7
END.
```
