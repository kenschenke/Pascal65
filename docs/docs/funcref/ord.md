# Ord

Returns the ordinal value of an ordinal type.

## Declaration

    FUNCTION Ord(value : ordinal) : integer;

## Description

*Ord* returns the integer ordinal value of an ordinal type.  This can be an enumerated type or an integer.

## Example ##

```
PROGRAM example;

TYPE
    Fruit = (apple, banana, pear, orange, peach);

VAR
    age : integer;
    snack : fruit;

BEGIN
    age := 10;
    fruit := pear;

    writeln(Ord(age));    // prints 10
    writeln(Ord(snack));  // prints 2
END.
```
