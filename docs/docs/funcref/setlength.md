# SetLength

Sets the length of a dynamic array.

## Declaration

    Procedure SetLength(Var arr : Array Of <element-type>; newLength : Integer);

## Description

*SetLength* changes the number of elements in a dynamic array. After the call
the array's valid indexes are 0 through newLength - 1. A length of 0 makes the
array empty.

The first parameter must be a dynamic array variable or parameter. The second
parameter can be any integer type.

When the array is made longer, the existing elements keep their values and the
new elements are initialized: numbers to 0, strings to empty strings, and
records the same way a new record variable is initialized. When the array is
made shorter, the elements past the new length are discarded, including any
strings or records they contain.

The new length must be between 0 and 32,767, or a runtime error occurs. A
runtime error also occurs if there isn't enough memory for the new length.

SetLength moves the array to a new block of memory. See
[Dynamic Array Storage](../../langref/arrays#dynamic-array-storage).

## Example

```
Program example;

Var
    names : Array Of String;
    i : Integer;

Begin
    SetLength(names, 3);
    names[0] := 'Alice';
    names[1] := 'Bob';
    names[2] := 'Carol';
    SetLength(names, 5);    // names[3] and names[4] are empty strings
    For i := Low(names) To High(names) Do
        Writeln(i, ': ', names[i]);
    SetLength(names, 0);    // empty, Length(names) is 0
End.
```

## See Also

[Arrays](../../langref/arrays), [Length](../length), [Low](../low),
[High](../high)
