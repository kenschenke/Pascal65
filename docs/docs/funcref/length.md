# Length

Returns the length of a string or an array.

## Declaration

    Function Length(str : String) : Byte;
    Function Length(arr : <array>) : Integer;

## Description

*Length* returns the number of characters in a string, or the number of
elements in an array.

For a string, *Length* returns a Byte.

For an array, *Length* returns an Integer. It works on static and dynamic
arrays. An empty dynamic array has a length of 0. For a multi-dimensional
static array, *Length* returns the number of elements in the first dimension.

## Example ##

```
Program example;

Var
    a : Array[1..10] Of Integer;
    d : Array Of Integer;

Begin
    Writeln(Length('hello, world'));  // Writes 12
    Writeln(Length(a));               // Writes 10
    Writeln(Length(d));               // Writes 0
    SetLength(d, 25);
    Writeln(Length(d));               // Writes 25
End.
```

## See Also

[Low](../low), [High](../high), [SetLength](../setlength)
