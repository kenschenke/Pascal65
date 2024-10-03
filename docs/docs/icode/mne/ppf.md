# PPF Instruction

## Synopsis

```
PPF <return label>
```

The **PPF** instruction pushes the stack frame for a routine being called
through a pointer. This is in contrast to the [PUF](/icode/mne/puf) instruction
which pushes the stack frame for a non-pointer routine call.

!!! warning

    The PPF instruction pushes the stack frame base pointer onto the CPU stack.
    It is very important to Call the **ASF** instruction after pushing the routine
    arguments onto the runtime stack. The ASF instruction pops the stack frame
    base pointer back off the CPU stack and sets the stack frame pointer.

## ReturnLabel Operand

This is the label for the caller's return point. This is where execution
will resume when the routine completes.

