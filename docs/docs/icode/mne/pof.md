# POF Instruction

## Synopsis

```
POF <isFunction> <isLibrary>
```

## Description

The **POF** instruction pops the stack frame for a routine. After removing
the stack frame, this instruction resumes execution with the caller's code.

## IsFunction Operand

This is non-zero if the routine is a function (returns a value).

## IsLibrary Operand

This is non-zero if the routine is in a library. This is important
because library routines are called with a 6502 JSR instruction.
Declared routines in the Pascal code are called with a JMP instruction.
