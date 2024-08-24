# IOResult

Return result of last file operation.

## Declaration

    Function IOResult : Word;

## Description

*IOResult* returns the result of the last file operation. If the return value is zero,
the operation was successful. If non-zero, an error occurred. This function clears
the result.

Following is a list of the possible values:

|Value|Description             |
|-----|------------------------|
|0    |No error                |
|2    |File not found          |
|4    |Too many open files     |
|7    |Invalid filename        |
|102  |File not assigned       |
|103  |File not open           |
|104  |File not open for input |
|105  |File not open for output|
|106  |File currently open     |
|150  |Disk is write protected |
|152  |Drive not ready         |

## Example ##

```
Program example;

Var
    fh : File Of Integer;

Begin
    Assign(fh, 'bad*filename');  // Filename cannot contain '*'
    Writeln('IOResult = ', IOResult);  // writes 'IOResult = 7'
End.
```
