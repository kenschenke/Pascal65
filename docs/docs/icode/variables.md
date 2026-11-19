# Variables

Variables in the intermediate code are always stored on the runtime stack. They are
referenced relative to the current scope level and an offset within that level. For example,
if the current scope is level 2 and a variable reference is level 1 and offset 3, then
the variable is located one level up and the fourth variable in that scope. Offsets
are zero-based.

## Operands

There are four operands that reference variables. The operands are used by the
[PSH](../mne/psh) instruction. All four operands are accompanied by four pieces
of data: variable type, scope level, offset within the scope, and frame.

The frame matters only for a global (level 1) variable. The program's global
scope holds the program's own variables, then each unit's and library's. The
part a module owns is its frame, listed in the file's frames table (see
[frames](../intro#frames)). A frame of 0 means the module's own variables;
otherwise it is the number of a frame in the table, from 1, and the offset is
counted from that frame's first variable.

|Operand|Description                       |
|-------|----------------------------------|
|VDR    |Variable, direct-read             |
|VDW    |Variable, direct-write            |
|VVR    |Variable read by reference (var)  |
|VVW    |Variable, write by reference (var)|

### VDR

This operand instructs the runtime to read the variable value directly. The value
is located by using the scope level and offset. The value of the variable is left
on the runtime stack.

### VDW

This operand instructs the runtime to locate the address of the variable's storage
on the runtime stack using the variable's scope level and offset. The address of the
variable is left on the runtime stack to be later used by the [SET](../mne/set) instruction.

### VVR

This operand instructs the runtime to locate the address of the variable's storage
and read the value. When variables are passed to routines by reference (the Var keyword),
the address of the caller's copy of the variable is passed to the routine. The value
of the caller's copy of the variable is left on the runtime stack.

### VVW

This operand instructs the runtime to locate the address of the variable's storage.
When variables are passed to routines by reference (the Var keyword), the address of the
caller's copy of the variable is passed to the routine. The address of the caller's
copy is left on the runtime stack to be later used by the [SET](../mne/set) instruction.
