# Object File

The object file must be a specific format in order for the linker to include
the object code into the program file.  The file needs to be organized in a way
that its code is relocatable.  This is mainly accomplished by using a jump table
at the beginning of the code and the code being assembled to a page boundary.

The strategy to relocate object code is heavily inspired by the way C64OS
handles loadable drivers.  A huge thanks goes out to Greg Nacu.  Please take
the time to read his blog post on drivers and relocatable code before continuing.
You can find it at <https://c64os.com/post/relocatable_6502>.

As Greg discusses in his blog, relocatable code must be assembled to start at a
page boundary.  As with any Commodore PRG file, the first two bytes of the object
file specify its starting address.  Since it starts on a page boundary, the first
byte must be zero.  The second byte specifies the page number.  The trick is to
identify one or more consecutive page numbers not used anywhere in your object
code and re-assemble the code to start at that page.  As Greg discussed, $FC
is not a valid 6502 opcode, not a commonly used PETSCII code, and tends not to be
used in code.  A Python program, scanner.py, is available in the Pascal 65 GitHub
repo.  It will scan an object file and give you possible candidates for unused
pages.

## Jump Table

As mentioned previously, an object file consists of a jump table at the beginning
immediately following the load address.  The jump table is used to call functions
and procedures in the library.  Just like the Commodore KERNAL, each jump table
entry is three bytes: a JMP instruction, followed by the internal address within
the library for the routine's entry point.  The table is also used for public
variables declared in the library's interface. Each public variable takes
up two bytes in the jump table. During program initialization, storage space for
that variable will be allocated on the runtime stack and the address of the
variable's storage will be placed in the jump table.

### Important

Please re-read the last sentence in the previous paragraph. It is important to
understand that the location in the jump table contains the *address* for the
variable's storage, not the variable's value. For records, arrays, and strings,
the address in the jump table points to the *address* of the variable's heap.
See the pages on arrays, strings, and records for more information on how
Pascal 65 organizes the data in memory.

The entries in the jump table must appear in the same order in which they are
declared in the interface section.  This means that variables (if any) will
always appear before functions and procedures.

### Library Initialization and Cleanup

The first two entries in the library jump table are reserved for library
initialization and cleanup. The initialization routine, the first entry
in the jump table, is called during program initialization before any
user code is called. The cleanup routine, the second entry in the jump
table, is called after all user code completes.

These two entries must be the first two in the jump table. If a library
has no need for initialization or cleanup, the routines can jump to
an RTS instruction or be RTS followed by two bytes such as NOP.
