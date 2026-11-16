# LibCallRoutine

This routine calls a Pascal routine from a library. Before calling the routine,
the library must create the stack frame header and push the routine's parameters
onto the runtime stack. See [this page](../libraries/stack.md) for more
information about the runtime stack.

After the routine returns, the library must call
[LibStackCleanup](libstackcleanup.md), which removes a byte this routine
leaves on the CPU stack. An interrupt handler that calls a Pascal routine
must also bracket the call with [IrqCallBegin and IrqCallEnd](irqcall.md).

## Inputs

### Routine Pointer

The pointer to the Pascal routine is expected at the top of the runtime
stack. The [PushEax](../runtime/pusheax.md) routine pushes values to the stack.

## Outputs

None

[LibStackHeader](../runtime/libstackheader.md)
