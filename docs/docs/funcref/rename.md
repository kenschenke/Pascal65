# Rename

Rename a file

## Declaration

    Procedure Rename(Var f : File; newname : String);

## Description

*Rename* renames a file. The original filename is set with the **Assign** procedure.
The file must be closed to rename it.

## Errors

If an error occurs, *IOResult* returns an error code. IOResult can be
one of the following:

|Number|Description        |
|------|-------------------|
|0     |No error           |
|2     |File not found     |
|7     |Invalid filename   |
|102   |File not assigned  |
|106   |File currently open|

## Example ##

```
Program example;

Var
    f : Text;

Begin
    Assign(f, 'oldname');
    Rename(f, 'newname');
End.
```
