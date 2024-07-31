# DVI Instruction

## Synopsis

```
DVI <operand-1 data type> <operand-2 data type> <result type>
```

## Description

The **DIV** instruction performs an integer division on two numbers
on the runtime stack.
Both numbers are popped off the stack and replaced by the result.
The numbers are referred to as operand-1 and operand-2, with
operand-1 below operand-2 on the stack. The operation is performed as
operand-1 Div operand-2.

### Data Type Operands

The operands are the data type of the values.

## See Also

[ADD](/icode/mne/add), [SUB](/icode/mne/sub), [DIV](/icode/mne/div),
[MUL](/icode/mne/mul), [Data Types](/icode/types)
