# StringOfChar

Returns a string filled with a character.

## Declaration

    FUNCTION StringOfChar(ch : char; count : byte) : string;

## Description

*StringOfChar* returns a string filled with the specified character.

## Example ##

```
PROGRAM example;

BEGIN
    writeln(stringofchar('*', 40));
END.
```
