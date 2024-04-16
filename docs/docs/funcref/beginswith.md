# BeginsWith

Determines if a string begins with a substring.

## Declaration

    Function BeginsWith(str, sub : String) : Boolean;

## Description

*BeginsWith* returns a boolean indicating whether or not a string begins with a substring.

## Example ##

```
Program example;

Begin
    Writeln('Hello World begins with World: ', BeginsWith('Hello World', 'World'));
End.
```
