# SST Instruction

## Synopsis

```
SST <string memory buffer>
```

## Description

The **SST** instruction is used to set the initial value when a string
variable is declared. The memory for the string is allocated and the
address is pushed onto the runtime stack.

### String Operand

The operand is a 16-bit integer that refers to
a memory buffer containing the string literal. If the number is 0,
the string variable is an empty string.
