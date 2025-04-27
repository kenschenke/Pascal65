# PopEax

This routine pops a 32-bit value off the runtime stack.

On return, the A register contains the lowest byte and the X register
contains the next highest byte. The high bytes are placed
in *sreg*.

## See Also

[PushEax](../pusheax)
