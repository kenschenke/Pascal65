# UIC Instruction

## Synopsis

```
UIC <label>
```

## Description

The **UIC** instruction calls a unit's init block. The block pushes the
unit's variables onto the runtime stack and initializes them, then
returns with [UIR](../uir).

A unit's variables are part of the program's global (level 1) stack
frame, after the program's own variables, in the order of the units. The
program's startup calls each unit's init block in that order. The block
belongs to the unit's own code, so a unit sets up its own variables.

Unlike a routine call ([PUF](../puf), [JSR](../jsr)), **UIC** doesn't push
a stack frame: the values the block pushes stay on the stack as the
unit's variables when it returns.

A library unit has no init block. Its variables are pushed by the
program's startup itself.

### Label Operand

The operand is the label of the unit's init block.
