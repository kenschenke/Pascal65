# Memory Heap

The Pascal65 runtime library maintains a memory heap that is dynamically
allocated and freed throughout the lifetime of a program. The memory heap
is primarily used to store arrays, records, and string variables.

If a library routine needs to modify the length of a string variable, it
is necessary to allocate a new string and free the old one.

## Allocating Memory

The **rtHeapAlloc** routine allocates a new block of memory.
The lower byte of the size is passed in A and the upper byte in X.
The pointer is returned in A and X. If the memory could not be allocated
a runtime error is generated and the program exits immediately.

## Freeing Memory

The **rtHeapFree** routine frees a block of memory. The lower byte of
the block is passed in A and the upper byte in X.
