# Calling Pascal Routines

!!! warning

    This feature is not yet implemented and the information in this
    document will likely change.

Libraries can call Pascal routines if a pointer to the routine has been
provided. The most common use case would be for a Pascal program to 
register a callback.

Calling a Pascal routine is a four step process.

  1. Create the stack frame header
  2. Push parameters onto the runtime stack
  3. Call the routine
  4. Clean up the runtime stack

If you have not read the page on the [runtime stack](stack.md) yet, please do so
before continuing.

## Return Address

Calls to Pascal routines are done via JMPs instead of JSRs. This means the
runtime needs to know the return addresses to return control to the library routine.
Since libraries are relocatable, this presents a bit of a challenge. To understand this
challenge, please read the page on [object files](objfile.md).

There are several legitimate ways to determine the address of something at runtime.
What we really need to know is the value of the program counter of a particular
piece of code. [This page](http://forum.6502.org/viewtopic.php?f=2&t=1250) discusses
a few of the techniques. One possible way used by the sprites library is to JSR to a
label then pop the return address off the stack.

For example, if the label **returnFromCall** is the return point, this piece of code
demonstrates how to determine the address of the label. **addrL** and **addrH** will
contain the low and high value of the return address.

        jmp getReturnAddress
    setAddress:
        pla         ; Pop address of return point off CPU stack and add 1
        clc
        adc #1
        sta addrL
        pla
        adc #0
        sta addrH

        ; ...
    
    getReturnAddress:
        jsr setAddress
    returnFromCall:
        ; This is where execution will continue when returning from the
        ; call to the Pascal routine.

## Create the Stack Frame Header

A Pascal routine's stack frame consists of a 16-byte header. This header
is situated below the routine's parameters and local variables and contains
important information, including the return address of the caller.

The first step in calling a Pascal routine is to create the stack frame header.
This is accomplished by calling the runtime routine
[LibSFHeader](../runtime/libsfheader.md). This routine needs to know the return
address of the caller and the pointer to the routine being called.

## Passing Parameters

After the stack frame header has been created, the routine's parameters must
be pushed onto the stack. This is done by calling the
[PushEax](../runtime/pusheax.md) runtime routine. Parameters are pushed on to
the stack in order of declaration, from left to right.

## Call the Routine

After the runtime stack has been set up the routine can be called by
the [LibCallRoutine](../runtime/libcallroutine.md).

## Clean Up the Runtime Stack

When the Pascal routine returns, the stack frame header and parameters must
be removed from the stack.
