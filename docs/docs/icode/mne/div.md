# DIV Instruction

## Synopsis

```
DIV <operand-1 data type> <operand-2 data type>
```

## Description

The **DIV** instruction divides two numbers on the runtime stack.
Both numbers are popped off the stack and replaced by the result.
The numbers are referred to as operand-1 and operand-2, with
operand-1 below operand-2 on the stack. The operation is performed as
operand-1 / operand-2.

### Data Type Operands

The operands are the data type of the values.

## See Also

[SUB](/icode/mne/sub), [MUL](/icode/mne/mul), [ADD](/icode/mne/add),
[DVI](/icode/mne/dvi), [Data Types](/icode/types)
