# SET Instruction

## Synopsis

```
SET <variable type> <value type>
```

## Description

The **SET** instruction sets the value of a variable.
The instruction looks for two values on the runtime stack. From bottom to top,
the value to set then the memory address of the variable. Both values are
popped off the stack.

### Variable Type Operand

This operand is the data type of the variable.

### Value Type operand

This operand is the data type of the value.

## See Also

[Data Types](/icode/types)
