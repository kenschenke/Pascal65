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
