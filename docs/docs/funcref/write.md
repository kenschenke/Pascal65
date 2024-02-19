# Write, WriteLn, WriteStr

These routines output values to the screen, a file, or a string.

## Declaration

    PROCECURE Write([file, ] ...);
    PROCEDURE WriteLn([file, ] ...);
    FUNCTION WriteStr(...) : string;

## Description

*Write*, *WriteLn*, and *WriteStr* outputs values. Write and WriteLn output
to a file if the first parameter is a file. Otherwise they output to the screen
at the current cursor position. WriteStr writes output to a string object.

The routines can accept multiple parameters. Values are output with no spacing.

*WriteLn* behaves just like *Write* except a newline is written after the output.

## Data Types

These routines accept any of the scalar data types including integer, real, boolean,
character, string literal, and string data type. They do not support arrays or records.

## Field Width

If a parameter is followed by a colon and a value, the output is right-justified within
the field width. If the value is wider than the field width, the value is output without
any spaces. The field width can be an integer literal or any expression that results in
an integer.

## Precision

If the value is a real data type and the field width is followed by another colon and
an integer value, it specifies the number of digits to the right of the decimal point.
The value is rounded if necessary.

## Examples ##

```
PROGRAM example;

Var
    str : string;

BEGIN
    writeln('Hello, World!');
    writeln(1234:10);
    writeln(123.456:0:2);

    str := writestr(12345);
END.
```
