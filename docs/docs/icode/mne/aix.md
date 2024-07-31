# AIX Instruction

## Synopsis

```
AIX <data type>
```

## Description

The **AIX** instruction calculates the memory address of an element in an array.
The instruction looks for two values on the runtime stack to calculate the
element's memory address. From bottom to top, the address of the array heap then
the index. Both values are popped off the stack and replaced by the memory
address of the element.

### Data Type Operand

The operand is the data type of the index.

## See Also

[Data Types](/icode/types)
