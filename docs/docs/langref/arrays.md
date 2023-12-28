# Arrays

Pascal arrays are statically allocated and contain a fixed number of elements.  They can contain up to 65,535 elements and the array index must be in the range of -32,768 to 32,767.

## Syntax

Arrays are declared with the following syntax.

```
    <variable-name> : Array[<low-index>..<high-index>] Of <element-type>
```

The low index must be less than the high index.  It can be an integer, a character, or an enumeration.  Examples are:

```
arr1 : Array[-5..5] Of Integer;
arr2 : Array[0..10] Of ShortInt;
```

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
