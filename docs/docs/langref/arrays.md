# Arrays

Pascal arrays are statically allocated and contain a fixed number of elements.  They can contain up to 65,535 elements and the array index must be in the range of -32,768 to 32,767.

## Syntax

Arrays are declared with the following syntax.

```
    <variable-name> : Array[<low-index>..<high-index>] Of <element-type>
    <variable-name> : Array[<number-of-elements>] : <element-type>
```

The low index must be less than the high index.  It can be an integer, a character, or an enumeration.
If specifying the number of elements, the low index of the array will be zero and the high index will
be the number of elements less one.

Examples are:

```
arr1 : Array[-5..5] Of Integer;
arr2 : Array[0..10] Of ShortInt;
arr3 : Array[5] Of Integer;
```

## Initial Values in Arrays

The program can specify initial values for arrays by listing the values in parenthesis after the array declaration.

```
arr1 : Array[1..5] Of Integer = (10, 20, 30, 40, 50);
arr2 : Array[1..100] Of Integer = (99, 72, 35);
```

Notice the second array declaration did not specify values for all the array elements. The first three elements will be populated with the provided values but the remainder of the elements will contain whatever value happens to be in memory when the array is allocated.

Multi-dimensional arrays can also be initialized.

```
arr : Array[1..3,1..3] Of Integer = (
    (10, 20, 30), (40, 50, 60), (70, 80, 90)
);
```

!!! note ""

    If no initial values are provided, the array elements are initialized to 0.
    If the array contains string elements, they are initialized to empty strings.

## Accessing Array Elements

Array elements are accessed by using square brackets, like this:

```
    i := arr1[3];
    arr1[4] := j;
    arr[i] := j;
```

## Multi-Dimensional Arrays

Multi-dimensional arrays are declared like this:

```
arr1 : Array[-5..5,1..10] Of Integer;
```

In this example the outer index ranges from -5 to 5 and the inner index ranges from 1 to 10.

Elements can be accessed in one of two ways:

```
(* Either syntax is valid *)

arr1[3,5] := 1234;
arr1[3][5] := 1234;
```

## Array Storage

This section describes how Pascal65 stores arrays in computer memory.  It is not
necessary to know this information to write Pascal programs.  This is here
primarily for developers writing libraries and for those curious.

Arrays consist of a six byte header followed directly by the array elements.  The
header is as follows.

| Size    | Description                    |
| ------- | ------------------------------ |
| 2 bytes | Lower bound of the array index |
| 2 bytes | Upper bound of the array index |
| 2 bytes | Size of each array element     |

Each value in the header is a 16-bit signed value.

An array declared as

```
Array[1..10] Of Integer;
```

with the values

```
[ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
```

would look like this in memory

```
$01 $00 $0a $00 $02 $00 $01 $00 $02 $00 $03 $00 $04 $00 $05 $00
$06 $00 $07 $00 $08 $00 $09 $00 $0a $00
```

If the array element is a record the record values are stored directly
within the array's memory. If the array element is a string, the array
contains pointers to the strings.
