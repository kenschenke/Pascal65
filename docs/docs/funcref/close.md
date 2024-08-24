# Close

Close a file

## Declaration

    Procedure Close(Var f : File);

## Description

*Close* a file of type **File** or **Text**.

## Errors

If an error occurs, *IOResult* returns an error code. IOResult can be
one of the following:

|Number|Description  |
|------|-------------|
|0     |No error     |
|103   |File not open|

## Example ##

```
Program example;

Var
    fh : File Of Integer;

Begin
    Assign(fh, 'numbers');
    Rewrite(fh);
    // ...
    Close(fh);
End.
```
