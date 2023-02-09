# Chr

Returns the character for the PETSCII code.

## Declaration

    FUNCTION Chr(num : integer) : char;

## Description

*Chr* returns the character for the PETSCII code passed into the function.

## Example ##

```
PROGRAM example;

BEGIN
    writeln(Chr(65));  (* Writes A to the output *)
END.
```
