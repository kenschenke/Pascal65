# Pointers

Pointers are a powerful language feature and a source of confusion for new programmers.
If this topic does not make sense, it might take a few readings to grasp it. Hopefully
with some examples, it will click into place.

A pointer is a variable that *points* to another variable. In this case, *points* means
that the pointer variable is linked to the other variable. Updates to the pointer actually
update the variable pointed to by the pointer.

Here is a short example:

    Program PointerExample;
    
    Var
        i : Integer;
        p : ↑Integer;
    
    Begin
        p := @i;
        p↑ := 12345;
    End.

In this example, **i** is an integer and **p** is a *pointer* to an integer.
In the first line of code after the *Begin*, **p** is assigned to point to **i**.
The second line of code assigns the number 12345 to the variable *pointed at* by **p**.
Since the previous line of code pointed **p** at **i**, the second line of code
assigns 12345 to **i**.

!!! warning

    Pointers are very dangerous and code using them should be carefully checked.
    The Pascal65 compiler and runtime do not check if a program is using an
    uninitialized pointer, a pointer to a variable no longer in scope, or that a
    pointer is staying within the bounds of the variable it is pointed at.
    This is not a discouragement from using pointers. It is just something every
    programmer should be aware of.

## Pointer Syntax

The above example shows the pointer syntax without much explanation. This section describes
the pointer syntax in detail.

### Pointer Declaration

Pointers are declared by placing a ↑ in front of the data type in the declaration.
The PETSCII code for this is 94 (5e in hex). This also happens to be same as the
^ (carat) in ASCII. On a Commodore keyboard, this key is next to the RESTORE key.

A declaration of an integer pointer would look like this:

    p : ↑Integer;

When a pointer is declared, it is initialized with a value of **nil**.

### Assigning a Pointer

To assign a pointer (point it at a variable), use the at symbol @ in front of the
variable being pointed at.

    ptr := @int;

In this example, ptr now points to int.

### Changing the Pointed-at Value

To change the value of a variable being pointed at, place the ↑ character after the
pointer when assigning the value.

    ptr↑ := 12345;

This sets the variable being pointed at to 12345.

### Accessing the Pointed-at Value

To access (read) the value of the pointed-at variable, place the ↑ after the pointer.

    otherInt := ptr↑;

This sets **otherInt** to the value of the variable pointed at by **ptr**.

### Pointers to Array Elements

You can set a pointer to point at a specific element in an array.

    ptr := @arr[1];

This example points **ptr** at the element indexed by **1** in the array **arr**.

### Pointers to Records

To access fields in a record through a pointer, add ↑ to the pointer before the dot.

    ptr↑.age := 1234;
    height := ptr↑.height;

### Pointers to Arrays

A program can set a pointer to an array.

    ptr := @arr;

Array elements are accessed through the array like this.

    ptr↑[index]

## Pointer Math

Pointers become especially powerful when used to access data in multi-value data structures
such as arrays. By adding or subtracting to a pointer, the pointer moves through memory by
the size of the data type it points at. The **Inc** and **Dec** procedures also operate on
pointers. Consider the following example.

    Type
        ArrType = Array[1..5] Of Integer;
    
    Var
        Arr : ArrType;
        p : ↑Integer;
        i : Integer;
    
    Begin
        p := @Arr[1];
        For i := 1 To 5 Do Begin
            p↑ := i;
            Inc(p);
        End;
        // Arr is now (1, 2, 3, 4, 5);
    End.

## Pointer Comparison

Pointers can be compared to other pointers or to the value **nil** (zero).
