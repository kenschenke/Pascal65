# Calling Pascal Routines

Libraries can call Pascal routines if a pointer to the routine has been
provided. The most common use case would be for a Pascal program to 
register a callback with the library.

Calling a Pascal routine is a three step process.

  1. Create the stack frame header
  2. Push parameters onto the runtime stack
  3. Call the routine

The Pascal routine will clean up the runtime stack before it returns,
including the frame header.

!!! note

    If the routine is a **Procedure** the entire stack frame is cleaned up.
    If the routine is a **Function** the return value is left on the stack
    and is the responsibility of the library to remove it.

If you have not read the page on the [runtime stack](stack.md) yet, please do so
before continuing.

## Create the Stack Frame Header

A Pascal routine's stack frame consists of a 16-byte header. This header
is situated below the routine's parameters and local variables and contains
important information, including the return address of the caller.

The first step in calling a Pascal routine is to create the stack frame header.
This is accomplished by calling the runtime routine
[LibStackHeader](../runtime/libstackheader.md).

## Passing Parameters

After the stack frame header has been created, the routine's parameters must
be pushed onto the stack. This is done by calling the
[PushEax](../runtime/pusheax.md) runtime routine. Parameters are pushed on to
the stack in order of declaration, from left to right.

### Scalar vs Non-scaler Values

Scalar values are traditional built-in values that are stored entirely on the
stack such as integers and boolean. Non-scalar values are objects such as
strings, records, and arrays. They are stored in the heap and the stack
contains a pointer to the heap storage.

### Parameters By Value

When passing a parameter by value, the Pascal routine expects to get its own
copy of the value and is free to modify that value without affecting any of
the caller's data. That means that if the routine is being passed a non-scalar
value such as a string, the caller is expected to allocate a copy for the
routine. It is the caller's responsibility to allocate the memory, copy the value,
and free the memory when the routine returns.

### Parameters By Reference

When passing a variable by reference, the caller supplies a pointer to the
caller's data rather than the value itself. For a scalar parameter, the caller
puts the address to the value on the stack. For non-scalar, the caller must
put the address of the pointer on the stack. This is necessary to allow the caller
to modify and/or reallocate the variable as necessary.

## Call the Routine

After the runtime stack has been set up, the routine can be called by
the [LibCallRoutine](../runtime/libcallroutine.md).

## Clean Up the Runtime Stack (Functions Only)

If the Pascal routine is a **Function**, the return value must be removed
from the stack by calling the [PopEax](../runtime/popeax.md) routine.
