# LibStackCleanup

This routine cleans up the stack frame after a call to a Pascal routine.
See [this page](../libraries/stack.md) for more information about the runtime
stack and the stack frame header.

## Inputs

### Function Flag

Pass 0 in A if the Pascal routine is a procedure or non-zero if the
routine is a function. For function calls, the return value is left
on the runtime stack.

## Outputs

None

[LibStackHeader](../libstackheader)
