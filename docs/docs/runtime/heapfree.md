# HeapFree

This routine frees a block of memory previous allocated with *HeapAlloc*.

## Inputs

The A register contains the lower byte of the memory address to free. The
X register contains the upper byte.

## Example

```
; Free the memory block in ptr1
lda ptr1
ldx ptr1+1
jsr rtHeapFree
```

## See Also

[HeapAlloc](../heapalloc)
