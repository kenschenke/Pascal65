# GTE Instruction

## Synopsis

```
GTE <operand-1 data type> <operand-2 data type>
```

## Description

The **GTE** instruction performs a greater-than-or-equal comparison between the two
values on the runtime stack. Both values are popped off the stack and replaced
by the boolean result. The values are referred to as operand-1 and operand-2,
with operand-1 below operand-2 on the stack. The comparison is performed as
operand-1 >= operand-2.

### Data Type Operands

The operands are the data type of the values.

### String Operands

If either operand is a string kind (`TYPE_STRING_LITERAL`, `TYPE_STRING_VAR`,
`TYPE_STRING_OBJ` or `TYPE_ARRAY`, an array of characters), the values are
compared as strings, character by character in PETSCII order. The other
operand is a string kind or a `TYPE_CHARACTER`, which is compared as a string
one character long. A `TYPE_STRING_OBJ` operand is freed after the
comparison. Two `TYPE_CHARACTER` operands are compared by their codes.

## See Also

[GRT](../grt), [LST](../lst), [LSE](../lse),
[EQU](../equ), [NEQ](../neq), [Data Types](../../types)
