# EndsWith

Determines if a string ends with a substring.

## Declaration

    Function EndsWith(str, sub : String) : Boolean;

## Description

*EndsWith* returns a boolean indicating whether or not a string ends with a substring.

## Example ##

```
Program example;

Begin
    Writeln('Hello World ends with World: ', EndsWith('Hello World', 'World'));
End.
```
