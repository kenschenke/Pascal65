# ARR Instruction

## Synopsis

```
NEW <label>
```

## Description

The **ARR** instruction allocates and initializes the arrays for the
current program scope. The operand is a location label referring to the
BSS data block containing the array initialization record(s). Refer to
the *Array Initialization* section of codegen.h in the source code
for more information on this.

### Label Operand

The label of the location of the array initialization block.
