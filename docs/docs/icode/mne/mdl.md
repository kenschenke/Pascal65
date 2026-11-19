# MDL Instruction

## Synopsis

```
MDL <frame>
```

## Description

The **MDL** instruction starts the code of a module: a unit's, or the
program's again after the units'. It generates no code. Until the next
MDL, a global [variable](../../variables) operand whose frame is 0 is in
this module's frame.

The operand is an unsigned byte: the module's number in the frames table
(see [Intermediate Code](../../intro)), from 1, or 0 for the program or a
unit with no variables. Code before the first MDL is the program's.

A program's icode holds its units' code too. Each unit's code (its init
block and routines) starts with MDL, so a unit names its own variables
with frame 0, as it will when it has an icode file of its own. MDL is
written only when the frame changes.
