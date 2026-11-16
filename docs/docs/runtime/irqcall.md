# IrqCallBegin and IrqCallEnd

These routines let a library's interrupt handler call a Pascal routine,
such as a callback the program registered.

## Why they are needed

An interrupt can stop the program anywhere, even in the middle of a
runtime routine. A Pascal routine called from the handler uses the same
zero page and the same runtime variables as the program, and it reaches
the program's variables through the runtime stack frame that was current
when it was called. Without these routines, the callback can change a
value the program is in the middle of using, or write to the wrong
variables.

*IrqCallBegin*:

- Saves the runtime's zero page ($04-$65) and the runtime variables that
  expressions, assignments and declarations use for a moment.
- Moves the runtime stack pointer down 32 bytes, so the callback can't
  change a value the program has just popped and is still reading.
- Sets the current stack frame and nesting level to the program's own,
  so the callback's static link points at the program's variables.

*IrqCallEnd* puts back everything *IrqCallBegin* saved. The calls don't
nest: the handler must not call *IrqCallBegin* again before
*IrqCallEnd*.

## Calling a routine from an interrupt

    jsr rtIrqCallBegin
    ; Push the routine pointer and set up the stack frame
    jsr pushCallbackPointer     ; the routine and its nesting level
    jsr rtLibStackHeader
    ; Push the parameters
    lda param
    ldx #0
    stx sreg
    stx sreg+1
    jsr rtPushEax
    ; Call the routine
    jsr pushCallbackPointer
    jsr rtLibCallRoutine
    ; Pop the parameters and clean up the stack frame
    jsr rtPopEax
    lda #0                      ; 0 = procedure
    jsr rtLibStackCleanup
    jsr rtIrqCallEnd

[LibCallRoutine](libcallroutine.md) leaves a byte on the CPU stack that
[LibStackCleanup](libstackcleanup.md) removes, so the handler must call
both. `pushCallbackPointer` stands for the library's own routine that
pushes the four bytes it saved from [LibLoadParam](libloadparam.md) when
the program registered the callback.

## Rules for callbacks

Document these for the library's users:

- The callback must be declared at the program's outer level, not inside
  another procedure or function.
- It must be short and must not wait for anything. Other interrupt
  handlers wait until it returns.
- It can change the program's variables, do arithmetic and call library
  routines meant for it. It must not write to the screen or a file, read
  the keyboard, or work with strings: those keep state of their own that
  isn't saved.

## Inputs

None

## Outputs

None. *IrqCallBegin* and *IrqCallEnd* change A and X.
