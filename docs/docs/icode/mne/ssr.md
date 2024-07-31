# SSR Instruction

## Synopsis

```
SSR
```

## Description

The **SSR** instruction reads a character from a string, at a given subscript.
The address of the string is expected at the top of the stack. The subscript
is below the address on the stack. Both values are popped off the stack and
replaced by the character at the subscript.
