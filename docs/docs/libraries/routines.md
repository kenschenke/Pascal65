# Library Routines

This document describes how to use the runtime library's routines to access
parameters on the runtime stack and how to return a value to the caller.

## Parameters

When a Pascal program makes a call to a library's routine, the parameters
are pushed onto the runtime stack and remain there until the routine returns.
Library routines can access the parameters directly using the **stackP** variable
or use the runtime library to access them.

Parameters to routines in Pascal can be passed by value or by reference.
This is an important disctinction and affects how library routines interact
with these parameters.

### By Value

Most parameters are passed by value and this is the simplist way to access
a parameter's value. The runtime library provides a routine,
[LibLoadParam](../../runtime/libloadparam) to access the value.

This routine loads a parameter off the stack into the A, X, and sreg locations.
The parameter number is passed into
[LibLoadParam](../../runtime/libloadparam) in the A register.
Parameters are numbered starting at zero, in the order declared.

On return, the A register holds the least-significant byte. The X register holds
the next most significant byte. sreg and sreg + 1 hold the next most significant
bytes.

A call to [LibLoadParam](../../runtime/libloadparam) might look like this:

```
lda #1    ; access the second parameter
jsr rtLibLoadParam
sta tmp1  ; store the least-significant byte
stx tmp2  ; store the next most significant byte
```

### By Reference

Parameters by reference are declared in Pascal using the **Var** keyword. For these
parameters, the runtime stack contains a pointer to the value rather than the value
itself.

[LibLoadParam](../../runtime/libloadparam) will return the pointer in A (lower byte) and X (upper byte).

The routine may modify the value pointed to by the pointer or might wish to update
the pointer itself. This is most common when the caller is passing a string by
reference. If the string length changes, the routine must allocate a new string
value on the heap and modify the pointer on the runtime stack. This is done with
the [LibStoreVarParam](../../runtime/libstorevarparam) routine. See the topic on the
memory heap for information on how to allocate and free memory on the heap.

The [LibStoreVarParam](../../runtime/libstorevarparam) routine looks for the new value
in A (lower byte), X (next most significant byte) and sreg (upper bytes). The
parameter number is passed in Y.

### Records and Arrays

When a record or array is passed into a library routine, the runtime stack contains
a pointer to the array or record in the memory heap. If the parameter was passed by
value, the library routine is provided with a copy. For parameters passed by reference
the pointer points to the caller's copy of the variable.

## Returning Values

To return a value to the caller, use the [LibReturnValue](../../runtime/libreturnvalue)
routine. The lower byte is passed in A, the next byte in X, and the upper bytes in
sreg and sreg + 1.
