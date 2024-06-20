# Inc

Increments a variable.

!!! warning

    Due to technical limitations the Inc procedure is currently disabled.
    A workaround is under development.

## Declaration

    Procedure Inc(num);
    Procedure Inc(num, increment);

## Description

*Inc* increments the variable passed in the first parameter. If a
second parameter is provided, the variable is incremented by that amount.

The *Inc* procedure supports all integer types (signed and unsigned),
enumeration types, and character. If the second parameter is present
it must be an integer (any size).

## Example ##

```
PROGRAM example;

VAR
    i : integer;

BEGIN
    i := 5;
    Inc(i);  // i is now 6
    Inc(i, 3); // i is now 9
END.
```
