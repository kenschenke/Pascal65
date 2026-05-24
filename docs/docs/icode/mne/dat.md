# DAT Instruction

## Synopsis

```
DAT <type> <label> <length>
```

## Description

The **DAT** instruction defines a data segment in the intermediate code.

The contents of the segment immediately follow the two operands.

## Type Operand

One of the following:

|Number|Description              |
|------|-------------------------|
|0     |Scalar literals          |
|1     |Real number literals     |
|2     |Record declaration block |
|3     |String literals          |
|5     |Array declaration block  |

## Label Operand

This is a label for the data segment.

## Length

The length of the data in the segment.
