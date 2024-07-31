# BSL Instruction

## Synopsis

```
BSL <operand-1 data type> <operand-2 data type> <result type>
```

## Description

The **BSL** instruction performs a bitwise left-shift on a value
on the runtime stack. The value to shift is identified as operand-1
and sits on the runtime stack under the value that indicates the
number of positions to shift the value. Both values are popped off the stack
and replaced by the result. The operation is performed as
operand-1 << operand-2.

### Data Type Operands

The operands are the data type of the values.

## See Also

[BWA](/icode/mne/bwa), [BWO](/icode/mne/bwo), [BSR](/icode/mne/bsr),
[BWC](/icode/mne/bwc), [Data Types](/icode/types)
