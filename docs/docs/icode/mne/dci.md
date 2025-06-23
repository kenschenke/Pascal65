# DCI Instruction

## Synopsis

```
DCI <label> <type>
```

## Description

The **DCI** instruction initializes a record or array using a declaration block
in the data segment.

The address of the record or array is expected at the top of the stack and is
left on the stack. The declaration block layout is shown here.

### Array Declaration Block

|# Of Bytes|Description                               |
|----------|------------------------------------------|
|2         |Heap offset - # of bytes past heap pointer|
|2         |Low index of array (signed 16-bit integer)|
|2         |High index of array                       |
|2         |Element size                              |
|2         |Pointer to literal initializers           |
|2         |Number of literals supplied               |
|2         |Pointer to element declaration block      |
|1         |Element type (see list below)             |

### Record Declaration Block

The record declaration block starts with a 4-byte header
followed by a list of record fields to initialize. The
list is terminated by a single zero byte.

#### Record Header

|# Of Bytes|Description                                   |
|----------|----------------------------------------------|
|2         |Heap offset - # of bytes past heap pointer    |
|2         |Size of record                                |

#### List of Record Fields

|# Of Bytes|Description                                   |
|----------|----------------------------------------------|
|1         |Element type from below (0 = end of list)     |
|2         |Pointer to declaration block (record or array)|
|2         |Offset - # of bytes from start of record      |

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

[DCF](../dcf)
