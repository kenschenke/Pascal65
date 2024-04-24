# Operators

Pascal offers the usual operators in other languages, with only a few minor differences.

## Math Operators

| Operator | Description                          |
| -------- | -------------------------------------|
| +        | Addition and string concatenation    |
| -        | Subtraction                          |
| *        | Multiplication                       |
| /        | Division (real data types)           |
| Div      | Division (integer data types)        |
| Mod      | Modulus (integer division remainder) |

### Real Number Division

The / operator will always result in a real number, even if both operands are integers.

### Integer Division

The Div operator can only operate on two integers and the result is always an integer.

## Conditional Operators

| Operator | Description           |
| -------- | --------------------- |
| <        | Less than             |
| <=       | Less than or equal    |
| >        | Greater than          |
| >=       | Greater than or equal |
| <>       | Not equal             |
| And      | Boolean And           |
| Or       | Boolean Or            |
| Not      | Boolean negation      |

### Examples

```
If i < 5 Then Do ...

If (i >= 5) And (i <= 10) Then Do ...

If Not i < 0 Then Do ...

If (i < 5) Or (i > 15) Then Do ...
```

Note that expressions on either side of **And** or **Or** must be surrounded by parenthesis.

## Bitwise Operators

These operators perform bitwise operations on numbers. That is, operations at the bit level. In order
to understand how bitwise operators work it is important to understand how numbers are represented in
binary notation (0's and 1's). For example, the number 6 is 110 in binary. As an 8-bit number it would be written as 0000 0110. To make it easier to read binary numbers, it is customary to put a space between
every 4 digits in written documentation.

| Operator | Description                      |
| -------- | -------------------------------- |
| &        | Bitwise AND                      |
| !        | Bitwise OR                       |
| <<       | Bitwise left shift               |
| >>       | Bitwise right shift              |
| @        | Bitwise complement (invert bits) |

### Bitwise AND

The bitwise AND operator (not to be confused with the conditional And operator)
combines two numbers and keeps only binary digits that are 1 in the same place in each number.
For example, 0110 1001 & 0011 1101 would be 0010 0001. It might be easier to visualize by
writing the numbers as such:

```
   0110 1001
 & 0011 1101
   ---- ----
   0010 1001
```

### Bitwise OR

The bitwise OR operator (not to be confused with the conditional Or operator)
combines two numbers and keeps binary digits that are 1 in either number.
For example:

```
   0110 1001
 ! 0011 1101
   ---- ----
   0111 1101
```

### Bitwise Left Shift

The bitwise left shift operator shifts the bits left a specified number of times.
The operation looks like this:

```
   num << 2
```

In this example, *num*'s bits are shifted left two times. The result would look
like this:

```
   Before: 0110 1100
   After:  1011 0000
```

### Bitwise Right Shift

The bitwise right shift operator shifts the bits right a specified number of times.
The operation looks like this:

```
   num >> 2
```

In this example, *num*'s bits are shifted right two times. The result would look
like this:

```
   Before: 0110 1100
   After:  0001 1011
```

### Bitwise Complement

The bitwise complement operator inverts the bits in a number. The operation would
look like this:

```
   num1 := @num2;
```

If num1 and num2 were the following values, this would be the before and after.

```
   num2: 0110 1000
   num1: 1001 0111
```
