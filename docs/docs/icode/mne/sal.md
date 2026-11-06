# SAL Instruction

## Synopsis

```
SAL <array declaration label>
```

## Description

The **SAL** instruction sets the length of a dynamic array. It implements the
[SetLength](../../../funcref/setlength) procedure.

The instruction looks for two values on the runtime stack. From bottom to top,
the address of the array variable, then the new length as a LongInt. Both
values are popped off the stack.

The first value is the address of the variable that holds the array's heap
pointer, not the heap address of the array itself. Resizing the array
allocates a new heap block, and the instruction stores the new block's address
in the variable. For a **Var** parameter it is the address of the caller's
variable.

The runtime allocates a block of 6 + length * element size bytes, copies the
array header and the elements that are kept, and sets the header's high index
to length - 1. New elements are initialized and dropped elements are freed.
Then the old block is freed. The element size and the old length are read
from the old block's header.

A length outside 0 to 32,767 is a "value out of range" runtime error. A block
size that doesn't fit in 16 bits is an "out of memory" runtime error.

### Array Declaration Label Operand

The operand is the label of the array's declaration block, the same block the
[DIA](../dia) instruction uses. The runtime uses it to find the element type
and, for an array of records, the record's declaration block, so it can
initialize new string and record elements and free dropped ones.

The limits in the block describe the array as it was declared, not its current
length. The runtime always reads the current length from the array header.

## Example

The intermediate code for `SetLength(a, n)`, where `a` and `n` are global
variables, `a` is a dynamic array and `n` is an Integer, looks like this:

```
PSH VDW b 1 0        ; address of the variable a
PSH VDR 4 1 4        ; the new length, n
CVI IBS 4 IBS 6      ; convert it from Integer to LongInt
SAL LBL di1234       ; set the length
```

The length is converted to a LongInt unless it already is a LongInt or a
Cardinal. A Cardinal above 2,147,483,647 arrives as a negative number and is
rejected by the range check. For a **Var** parameter, the first instruction is
`PSH VVW` instead of `PSH VDW`.

## See Also

[DIA](../dia), [NEW](../new)
