# MUL Instruction

## Synopsis

```
MUL <operand-1 data type> <operand-2 data type> <result type>
```

## Description

The **MUL** instruction multiplies two numbers on the runtime stack.
Both numbers are popped off the stack and replaced by the result.
The numbers are referred to as operand-1 and operand-2, with
operand-1 below operand-2 on the stack. The operation is performed as
operand-1 x operand-2.

### Data Type Operands

The operands are the data type of the values.

## See Also

[ADD](../add), [SUB](../sub), [DIV](../div),
[DVI](../dvi), [Data Types](../../types)
