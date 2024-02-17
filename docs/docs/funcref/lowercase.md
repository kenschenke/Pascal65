# LowerCase

Returns a string with all letters converted to lower case.

## Declaration

    FUNCTION LowerCase(str : string) : string;

## Description

*LowerCase* returns a copy of the input string with all letters converted
to lower case. Non alphabetic characters are unchanged.

## Example ##

```
PROGRAM example;

BEGIN
    writeln(lowercase('test string'));
END.
```
