# Assign

Set the filename for a file

## Declaration

    Procedure Assign(Var f : File; filename : String);

## Description

*Assign* sets the filename for a file of type **File** or **Text**.

## Errors

If an error occurs, *IOResult* returns an error code. IOResult can be
one of the following:

|Number|Description     |
|------|----------------|
|0     |No error        |
|7     |Invalid filename|

## Example ##

```
Program example;

Var
    fh : File Of Integer;
    ft : Text;

Begin
    Assign(fh, 'numbers');
    Assign(ft, 'words.txt');
End.
```
