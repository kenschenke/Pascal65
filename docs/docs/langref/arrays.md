# Arrays

Pascal65 supports two kinds of arrays: static and dynamic.

A static array is declared with its index range and contains a fixed number of
elements. It can contain up to 65,535 elements and the array index must be in
the range of -32,768 to 32,767.

A dynamic array is declared without an index range. It starts out empty and
its length is set while the program runs with the
[SetLength](../../funcref/setlength) procedure. See
[Dynamic Arrays](#dynamic-arrays) below.

## Syntax

Static arrays are declared with the following syntax.

```
    <variable-name> : Array[<low-index>..<high-index>] Of <element-type>
    <variable-name> : Array[<number-of-elements>] Of <element-type>
```

The low index must be less than the high index.  It can be an integer or a character.
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

## Dynamic Arrays

A dynamic array is an array whose length can change while the program runs.
It is declared by leaving out the index range.

```
    <variable-name> : Array Of <element-type>
```

Examples are:

```
Type
    TNames = Array Of String;

Var
    nums : Array Of Integer;
    names : TNames;
```

A dynamic array always starts at index 0. When it is declared it is empty: it
has no elements and no index is valid. The program gives it a length by calling
[SetLength](../../funcref/setlength).

```
Var
    nums : Array Of Integer;
    i : Integer;

Begin
    SetLength(nums, 10);    // nums[0] through nums[9]
    For i := 0 To 9 Do nums[i] := i * 2;
    SetLength(nums, 20);    // nums[0] through nums[9] are kept
    SetLength(nums, 5);     // nums[5] through nums[19] are dropped
    SetLength(nums, 0);     // empty again
End.
```

When an array is made longer, the existing elements keep their values. The new
elements are initialized the same way a new static array is: numbers are 0,
strings are empty, and records are initialized as described in
[Records](../records). When an array is made shorter, the dropped elements are
discarded, including any strings or records they contain.

The length must be between 0 and 32,767. A length outside that range is a
runtime error. A runtime error also occurs if there isn't enough memory for the
new length.

### Length, Low, and High

[Length](../../funcref/length) returns the number of elements in an array.
[Low](../../funcref/low) and [High](../../funcref/high) return its lowest and
highest index. All three work on static and dynamic arrays. For a dynamic
array, Low is always 0 and High is Length - 1, so an empty dynamic array has
a High of -1. This makes loops over a dynamic array safe even when it is empty.

```
For i := Low(nums) To High(nums) Do
    Writeln(nums[i]);
```

### Initial Values

A dynamic array can be initialized with values, just like a static array. The
number of values sets the initial length.

```
nums : Array Of Integer = (10, 20, 30);    // Length is 3, High is 2
```

### Dynamic Arrays as Parameters

A dynamic array can be passed to a procedure or function whose parameter is
declared as a dynamic array. Passed by value, the routine gets its own copy and
calling SetLength on the copy doesn't change the caller's array. Passed as a
**Var** parameter, the routine works on the caller's array, and SetLength
inside the routine changes the caller's array.

```
Type
    TIntArray = Array Of Integer;

Procedure Grow(Var a : TIntArray);
Begin
    SetLength(a, Length(a) + 1);
End;
```

A dynamic array declared inside a procedure or function is freed when the
routine exits.

### Character Arrays

Like static arrays of characters, a dynamic array of **Char** can be used with
[Read, ReadStr](../../funcref/read) and [Write, WriteStr](../../funcref/write).
It can also be the string ReadStr reads from. Arrays of any other type can't
be read or written as a whole.

## Restrictions

The following rules apply to arrays. The compiler reports an error if a
program breaks one of them.

* An array can't be assigned to another array as a whole (`a := b`). This
  applies to static and dynamic arrays. Copy the elements one at a time
  instead. Assigning to an element (`a[i] := x`) is fine.
* A dynamic array has only one dimension. A dynamic array can't be the element
  of another array (static or dynamic), and an array can't be the element of a
  dynamic array.
* A dynamic array can't be a field of a record.
* A file can't hold dynamic arrays (`File Of Array Of Integer`). A file of a
  static array is fine.
* A static array can't be passed to a parameter declared as a dynamic array,
  and a dynamic array can't be passed to a parameter declared as a static
  array. This applies to parameters passed by value and **Var** parameters.
* A function can't return an array, static or dynamic.

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

### Dynamic Array Storage

A dynamic array uses the same header. Its lower bound is always 0 and its
upper bound is the length less one. An empty dynamic array is just the six
byte header, with an upper bound of -1 (`$ff $ff`).

The header and the elements are one block of memory. When SetLength changes
the length, the runtime allocates a new block, copies the elements that are
kept, frees the old block, and stores the new block's address in the array
variable. The array's address therefore changes every time SetLength is called.

!!! warning ""

    Don't keep a pointer to a dynamic array's memory across anything that can
    call SetLength on that array. Read the address from the array variable
    again each time it is needed. A library routine that is given a dynamic
    array should find the array through the variable, and not hold on to the
    address after the routine returns.
