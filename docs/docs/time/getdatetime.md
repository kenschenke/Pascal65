# GetDateTime

Retrieves the current date and time from the system clock.

## Declaration

    Uses Time;

    Procedure GetDateTime(Var dt : DateTime);

## Description

This function retrieves the current date and time from the system clock.

## DateTime

The **DateTime** record is defined as

    DateTime = Record
        hour, minute, second, month, day : Byte;
        year : Word;
    End;

## Example ##

```
Program example;

Uses Time;

Var
    dt : DateTime;

Begin
    GetDateTime(dt);
End.
```
