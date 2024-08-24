# Erase

Erase (scratch) a file

## Declaration

    Procedure Erase(Var f : File);

## Description

*Erase* deletes a file. The filename is set with the **Assign** procedure.
The file must be closed to erase it.

## Errors

If an error occurs, *IOResult* returns an error code. IOResult can be
one of the following:

|Number|Description        |
|------|-------------------|
|0     |No error           |
|102   |File not assigned  |
|106   |File currently open|

## Example ##

```
Program example;

Var
    f : Text;

Begin
    Assign(f, 'myfile');
    Erase(f);
End.
```
