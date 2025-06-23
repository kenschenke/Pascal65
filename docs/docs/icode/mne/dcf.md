# DCF Instruction

## Synopsis

```
DCF <label> <type>
```

## Description

The **DCF** instruction frees a record or array using a declaration block
in the data segment.

The address of the record or array is expected at the top of the stack and is
removed from the stack. See the [DCI](../dci) instruction for more information on
the layout of the declaration block.

## Label Operand

This is a label linking to the declaration block in the data segment.

## Declaration Type

This is a number representing the type of declaration.

|Number|Description |
|------|------------|
|1     |Real numbers|
|2     |Record      |
|3     |String      |
|4     |File handle |
|5     |Array       |

## See Also

[DCI](../dci)
