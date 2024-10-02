# LibStackHeader

This routine creates the stack frame header in preparation for calling
a Pascal routine from a Library. See
[this page](../libraries/stack.md) for more information about the runtime
stack and the stack frame header.

## Inputs

### Routine Pointer

The pointer to the Pascal routine is expected at the top of the runtime
stack. The [PushEax](../runtime/pusheax.md) routine pushes values to the stack.

## Outputs

None

[LibCallRoutine](/runtime/libcallroutine)
