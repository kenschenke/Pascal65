# PUF Instruction

## Synopsis

```
PUF <routineLevel> <returnLabel>
```

## Description

The **PUF** instruction pushes the stack frame for a routine.
This is in contrast to the [PPF](../ppf) instruction
which pushes the stack frame for a call made through a routine pointer.

!!! warning

    The PUF instruction pushes the stack frame base pointer onto the CPU stack.
    It is very important to Call the **ASF** instruction after pushing the routine
    arguments onto the runtime stack. The ASF instruction pops the stack frame
    base pointer back off the CPU stack and sets the stack frame pointer.

## RoutineLevel Operand

This is the scope level of the routine. It is used to calculate the
static link portion of the stack frame. The stack link points to the
containing routine's stack frame.

## ReturnLabel Operand

This is the label for the caller's return point. This is where execution
will resume when the routine completes.

