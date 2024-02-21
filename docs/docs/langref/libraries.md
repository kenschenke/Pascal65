# Libraries

A library is a way to put object code into a program during the compile and
linking process.  Libraries are compiled or assembled into object code
ahead of time and can greatly speed up compilation time.

## Library Interface

A library consists of two files: an interface file and an object file.  The
interface file is very similar to a **Unit** file.  It is named
library-name.pas.  For example, the interface for a library called Math
would be named math.pas.  The object file would be named math.lib.  The syntax
for the interface file starts out just like a unit.  The interface section is
identical but the implementation section is left blank except for the addition
of the **library** keyword.

```
Unit Math;

Interface

Function Cos(num : Real) : Real;
Function Sin(num : Real) : Real;

Implementation Library

End.
```

## Object File

The object file must be a specific format in order for the linker to include
the object code into the program file.  The file needs to be organized in a way
that its code is relocatable.  This is mainly accomplished by using a jump table
at the beginning of the code and the code being assembled to a page boundary.

The strategy to relocate object code is heavily inspired by the way C64OS
handles loadable drivers.  A huge thanks goes out to Greg Nacu.  Please take
the time to read his blog post on drivers and relocatable code before continuing.
You can find it at <https://c64os.com/post/relocatable_6502>.

As Greg discussed in his blog, relocatable code must be assembled to start at a
page boundary.  As with any Commodore PRG file, the first two bytes of the object
file specify its starting address.  Since it starts on a page boundary, the first
byte must be zero.  The second byte specifies the page number.  The trick is to
identify one or more consecutive page numbers not used anywhere in your object
code and re-assemble the code to start at that page.  As Greg discussed, $FC
is not a valid 6502 opcode, not a commonly used PETSCII code, and tends not to be
used in code.  A Python program, scanner.py, is available in the Pascal 65 GitHub
repo.  It will scan an object file and give you possible candidates for unused
pages.

### Jump Table

As mentioned previously, an object file consists of a jump table at the beginning
immediately following the load address.  The jump table is used to call functions
and procedures in the library.  Just like the Commodore Kernal, each jump table
entry is three bytes: a JMP instruction, followed by the internal address within
the library for the routine's entry point.  The table is also used for public
variables declared in the library's interface.  The appropriate number of bytes
need to be reserved in the table to accommodate the variable.  For arrays, strings,
and records, the table entry will be the address within the heap.  The heap address
will be populated during program initialization.  It is not necessary for the
library to take any action to initialize this.  See the pages on arrays, strings, and
records for more information on how Pascal 65 organizes the data in memory.

The entries in the jump table must appear in the same order in which they are
declared in the interface section.  This means that variables (if any) will
always appear before functions and procedures.

### Pascal 65 Runtime Stack

Pascal 65 uses a runtime stack inspired by CC65.  When a routine is called in
a library, a stack frame is pushed onto the runtime stack followed by the
parameters.  If the routine is a function, the return value is left on the
runtime stack.  The Pascal 65 runtime will manage the stack, but library routines
need to read values on the stack to access parameters and send back return values.
Routines will not push or pop values off the stack, but will simply access them
using a stack frame base pointer located in zero page.

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
