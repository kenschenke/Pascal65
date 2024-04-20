# Read, ReadLn, ReadStr

These routines read values from the keyboard, a file, or a string.

## Declaration

    PROCECURE Read([file, ] ...);
    PROCEDURE ReadLn([file, ] ...);
    PROCEDURE ReadStr(Str : String; ...);

## Description

*Read*, *ReadLn*, and *ReadStr* input values. Read and ReadLn read input from
a file if the first parameter is a file. Otherwise they read from the keyboard.
ReadStr reads values from a string object.

The routines can accept multiple parameters.

*ReadLn* behaves just like *Read* except it consumes all keyboard input until
return is pressed.

## Data Types

These routines accept the following data types: integer, real,
character, character arrays, and string data type.

## Examples ##

```
PROGRAM example;

Var
    str : string;

BEGIN
    readln(str);
END.
```
