# DIR Instruction

## Synopsis

```
DIR <record declaration chunk number>
```

## Description

The **DIR** instruction initializes a record by referencing the declaration
chunk number. It is an interstitial messenger instruction that exists solely
to communicate from the intermediate code generation phase of the compiler to
the object code generation phase.

When the object code generation phase sees this instruction it generates a call
into the runtime to initialize a record. The declaration chunk number is used to
create a declaration block in the BSS segment of the PRG file that contains the
necessary information to initialize the record.

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

[DIA](../dia)
