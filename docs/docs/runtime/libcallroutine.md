# LibCallRoutine

This routine calls a Pascal routine from a library. Before calling the routine,
the library must create the stack frame header and push the routine's parameters
onto the runtime stack. See [this page](../libraries/stack.md) for more
information about the runtime stack.

## Inputs

### Routine Pointer

The pointer to the Pascal routine is expected at the top of the runtime
stack. The [PushEax](../runtime/pusheax.md) routine pushes values to the stack.

## Outputs

None

[LibStackHeader](../runtime/libstackheader.md)
