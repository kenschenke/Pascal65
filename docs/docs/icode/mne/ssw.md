# SSW Instruction

## Synopsis

```
SSW
```

## Description

The **SSW** instruction calculates the address of a subscript in a string.
The subscript is expected at the top of the stack. The address of the string
is below the subscript on the stack. Both values are popped off the stack and
replaced with the address of the character at the given subscript.
