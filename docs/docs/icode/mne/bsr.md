# BSR Instruction

## Synopsis

```
BSR <operand-1 data type> <operand-2 data type> <result type>
```

## Description

The **BSR** instruction performs a bitwise right-shift on a value
on the runtime stack. The value to shift is identified as operand-1
and sits on the runtime stack under the value that indicates the
number of positions to shift the value. Both values are popped off the stack
and replaced by the result. The operation is performed as
operand-1 >> operand-2.

### Data Type Operands

The operands are the data type of the values.

## See Also

[BWA](../bwa), [BWO](../bwo), [BSL](../bsl),
[BWC](../bwc), [Data Types](../../types)
