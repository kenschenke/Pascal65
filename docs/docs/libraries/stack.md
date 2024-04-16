# Pascal 65 Runtime Stack

Pascal 65 uses a runtime stack inspired by CC65.  When a routine is called in
a library, a stack frame is pushed onto the runtime stack followed by the
parameters.  If the routine is a function, the return value is left on the
runtime stack.  The Pascal 65 runtime will manage the stack, but library routines
need to read values on the stack to access parameters and send back return values.
Routines will not push or pop values off the stack, but will simply access them
using a stack frame base pointer located in zero page.

To simplify library development, the runtime library provides a few routines
for accessing parameters on the runtime stack and returning values to callers.
The remainder of this document descibres the runtime stack in detail. An
understanding is not necessary for library development but is included for
the curious.

The runtime stack is used to store every global and local variable as well
as the call stack for functions and procedures.  The stack starts at
$CFFF ($BFFF on the Mega65) and grows downward in memory to a maximum size of 2k.

The zeropage value stackP points to the base of the current scope's stack frame.  More accurately, it points to the next byte following the bottom of the stack
frame.  For example, on program startup stackP is $D000 ($C000 on the Mega65).
When a Pascal function or procedure is called, stackP temporarily points to the routine's stack frame then is restored to the caller's stack frame when the function or procedure returns.  The global stack frame's return value is actually at
$CFFC through $CFFF.  The return address is at $CFF8 through $CFFB. Values are
stored least-significant to most-significant in increasing address order.  So, the least-significant byte of the return value is at $CFFC.

The stack frame consists of a 16-byte header followed by each parameter passed
to the routine.  There are four values in each stack frame header, appearing
in the following order bottom to top.

1. Function return value (zero for program scope or procedures).
2. Return address of routine caller (zero for program scope).
3. Static link (point to base of stack frame for parent scope).
4. Dynamic link (point to base of stack frame of caller).

Routine parameters always consume 4 bytes on the runtime stack.
Consider thefollowing example routine.

```
    Function Multiply(num1, num2 : Integer) : Integer;
```

Assuming the base of the stack frame is $BFF0, the stack frame would
look like the below.  Recall that runtime stacks grow downward.

| Address | Offset From Stack Pointer | Description            |
| ------- | ------------------------- | ---------------------- |
| $BFEC   | -4                        | Function return value  |
| $BFE8   | -8                        | Routine return address |
| $BFE4   | -12                       | Static link            |
| $BFE0   | -16                       | Dynamic link           |
| $BFDC   | -20                       | num1                   |
| $BFD8   | -24                       | num2                   |
