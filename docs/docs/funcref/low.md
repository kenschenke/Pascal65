# Low

Returns the lowest index of an array.

## Declaration

    Function Low(arr : <array>) : Integer;

## Description

*Low* returns the lowest valid index of an array. It works on static and
dynamic arrays. For a dynamic array it is always 0, even when the array is
empty.

For a static array with a character index, *Low* returns the ordinal value of
the lowest index as an Integer.

## Example

```
Program example;

Var
    a : Array[-5..5] Of Integer;
    d : Array Of Integer;

Begin
    Writeln(Low(a));  // Writes -5
    Writeln(Low(d));  // Writes 0
End.
```

## See Also

[High](../high), [Length](../length), [SetLength](../setlength)
