# UpCase

Returns a string with all letters converted to upper case.

## Declaration

    FUNCTION UpCase(str : string) : string;

## Description

*UpCase* returns a copy of the input string with all letters converted
to upper case. Non alphabetic characters are unchanged.

## Example ##

```
PROGRAM example;

BEGIN
    writeln(upcase('test string'));
END.
```
