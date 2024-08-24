# Reset

Open a file for reading

## Declaration

    Procedure Reset(Var f : File);

## Description

*Reset* opens a file of type **File** or **Text** for reading.

## Errors

If an error occurs, *IOResult* returns an error code. IOResult can be
one of the following:

|Number|Description        |
|------|-------------------|
|0     |No error           |
|2     |File not found     |
|102   |File not assigned  |
|106   |File currently open|
|152   |Drive not ready    |

## Example ##

```
Program example;

Var
    fh : File Of Integer;
    i : Integer;

Begin
    Assign(fh, 'numbers');
    Reset(fh);
    Read(fh, i);
    Close(fh);
End.
```
