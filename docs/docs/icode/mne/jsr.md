# JSR Instruction

## Synopsis

```
JSR <routineLabel> <routineLevel> <isLibraryRoutine>
```

## Description

The **JSR** instruction calls a routine. The stack frame and parameters
must already have been set up prior to this instruction.

## RoutineLabel Operand

This is the label of the routine to call.

## RoutineLevel Operand

The scope level of the routine.

## IsLibraryRoutine Operand

This is non-zero if the routine is in a library. This is important
because library routines are called with a 6502 JSR instruction.
Declared routines in the Pascal code are called with a JMP instruction.
