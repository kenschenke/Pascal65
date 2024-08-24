# EOF

Check for end of file

## Declaration

    Function EOF(Var f : File) : Boolean;

## Description

*EOF* checks for end of file for a file of type **File** or **Text**.

## Example ##

```
Program example;

Var
    fh : File Of Integer;
    i : Integer;

Begin
    Assign(fh, 'numbers');
    Reset(fh);

    Repeat
        Read(fh, i);
    Until EOF(fh);

    Close(fh);
End.
```
