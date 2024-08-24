# Rewrite

Open a file for writing

## Declaration

    Procedure Rewrite(Var f : File);

## Description

*Rewrite* opens a file of type **File** or **Text** for writing. If a file with
that name already exists, it will be overwritten.

## Errors

If an error occurs, *IOResult* returns an error code. IOResult can be
one of the following:

|Number|Description            |
|------|-----------------------|
|0     |No error               |
|102   |File not assigned      |
|106   |File currently open    |
|150   |Disk is write protected|
|152   |Drive not ready        |

## Example ##

```
Program example;

Var
    fh : File Of Integer;
    i : Integer;

Begin
    Assign(fh, 'numbers');
    Rewrite(fh);
    Write(fh, i);
    Close(fh);
End.
```
