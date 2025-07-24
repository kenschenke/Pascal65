# DIA Instruction

## Synopsis

```
DIA <array declaration chunk number>
```

## Description

The **DIA** instruction initializes an array by referencing the declaration
chunk number. It is an interstitial messenger instruction that exists solely
to communicate from the intermediate code generation phase of the compiler to
the object code generation phase.

When the object code generation phase sees this instruction it generates a call
into the runtime to initialize an array. The declaration chunk number is used to
create a declaration block in the BSS segment of the PRG file that contains the
necessary information to initialize the array.

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

[DIR](../dir)
