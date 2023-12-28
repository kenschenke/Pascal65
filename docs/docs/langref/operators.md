# Operators

Pascal offers the usual operators in other languages, with only a few minor differences.

## Math Operators

| Operator | Description                          |
| -------- | -------------------------------------|
| +        | Addition                             |
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
