# LSE Instruction

## Synopsis

```
LSE <operand-1 data type> <operand-2 data type>
```

## Description

The **LTE** instruction performs a less-than-or-equal comparison between the two
values on the runtime stack. Both values are popped off the stack and replaced
by the boolean result. The values are referred to as operand-1 and operand-2,
with operand-1 below operand-2 on the stack. The comparison is performed as
operand-1 <= operand-2.

### Data Type Operands

The operands are the data type of the values.

## See Also

[GRT](/icode/mne/grt), [GTE](/icode/mne/gte), [LST](/icode/mne/lst),
[EQU](/icode/mne/equ), [NEQ](/icode/mne/neq), [Data Types](/icode/types)
