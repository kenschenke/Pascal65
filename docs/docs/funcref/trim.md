# Trim

Returns a trimmed string.

## Declaration

    FUNCTION Trim(str : string) : string;

## Description

*Trim* returns a copy of the input string with leading and trailing
spaces removed.

## Example ##

```
PROGRAM example;

BEGIN
    writeln(trim('  test string  '));
END.
```
