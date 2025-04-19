# AddIrqHandler

This routine adds an IRQ handler to be called by the KERNAL when an
interrupt occurs.

!!! warning
    The caller must disable CPU interrupts with **sei** before calling
    this routine and re-enable interrupts with **cli** when ready.
    The routine returns the address of the next interrupt to JMP to,
    so it is important to not re-enable interrupts until the caller has
    a chance to store the address. If a CPU interrupt were to occur after
    the caller's handler was installed but before the caller had the proper
    address for the next handler, the CPU would likely be sent to a random address
    and crash the system.

## Inputs

### Interrupt Handler Address

A contains the low byte of the handler address. X contains the high
byte.

### Interrupt Mask

Y contains the interrupt mask. This is combined with the interrupt
mask currently in place. The mask is stored in **$D01A** and the bit
values are defined on page 151 of the
*Commodore 64 Programmer's Reference Guide*. Please note: the handler
will be called for every interrupt. It is the handler's responsibility
to ignore interrupts not triggered on its behalf.

Bit 0 of this mask indicates a raster interrupt. This routine sets the
raster interrupt to occur at row 210. If the caller wishes to update
this value for things such as sprite multiplexing, please keep in mind
that other handlers might expect the raster interrupts to only occur
once per frame so things such as sprite animation and music might be
affected.

## Output

A contains the low byte of the next handler to call in the chain.
X contains the high byte. It is the handler's responsibility to JMP
to this address when it completes.

## Writing a Handler

Your interrupt handler will look in **$D019** to determine the type of
interrupt and whether your handler will react. Do not reset or unlatch
any bits in **$D019** as discussed in the
*Commodore 64 Programmer's Reference Guide*. That is handled by the
runtime library. This is so any additional handlers can inspect the
mask bits.
