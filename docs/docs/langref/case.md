# Case Statement

The **Case** statement evaluates a variable and executes a statement or statement block that matches a value or values.

## Syntax

The statement(s) for a value or group of values can be a single statement or a statement block.  Both are shown.

```
Case i Of
    1, 2, 3: Writeln('One, two, or three');
    4: Writeln('Four');
    5, 6: Begin
        Write('Five');
        Writeln(' or Six');
    End;
End;
```
