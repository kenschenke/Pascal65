# HeapAlloc

This routine allocates a block of memory from the heap.

If the block cannot be allocated a runtime error will be thrown
and the program will exit immediately.

## Inputs

The A register contains the lower byte of the desired memory block size.
The X register contains the upper byte of the size.

## Return Value

The address of the memory block is returned in A and X. The A register
contains the lower byte of the address and the X register contains the
upper byte.

## Example

```
; Allocate 20 bytes of memory
lda #$14
ldx #$00
jsr rtHeapAlloc
sta ptr1            ; Save the block address in ptr1
stx ptr1+1
```

## See Also

[HeapFree](/runtime/heapfree)
