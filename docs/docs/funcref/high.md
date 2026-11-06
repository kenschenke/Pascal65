# High

Returns the highest index of an array.

## Declaration

    Function High(arr : <array>) : Integer;

## Description

*High* returns the highest valid index of an array. It works on static and
dynamic arrays. For a dynamic array it is the length less one, so an empty
dynamic array has a *High* of -1. A loop from *Low* to *High* then runs no
times.

For a static array with a character index, *High* returns the ordinal value of
the highest index as an Integer.

## Example

```
Program example;

Var
    a : Array[1..10] Of Integer;
    d : Array Of Integer;

Begin
    Writeln(High(a));  // Writes 10
    Writeln(High(d));  // Writes -1
    SetLength(d, 4);
    Writeln(High(d));  // Writes 3
End.
```

## See Also

[Low](../low), [Length](../length), [SetLength](../setlength)
