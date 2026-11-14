# Usage

**Pascal65** is both an integrated development environment as well as a compiler. If desired,
the compiler can be used independently of the IDE.

## Starting the IDE

The IDE can be started by running:

```
DLOAD"*"
RUN
```

or

```
DLOAD"PASCAL65"
RUN
```

The compiler can be run inside the IDE and this is the normal workflow during development.

## Compiling in the IDE

**F7** compiles the current file and **F5** compiles and runs it. Both save every open
file first. After a compile, the IDE goes straight back to the editor. If the compile
found an error, **F5** doesn't run the program.

The line above the key help at the bottom of the screen shows the result of the last
compile:

```
Build Success: Error(s): 0, Warning(s): 3
Build Failed: Error(s): 2, Warning(s): 0
```

**F11** steps to the next error or warning and **F9** to the previous one. The line then
shows the message, its line and its file, and which entry it is:

```
Error Incompatible assignment, line 16, hello.pas                   Showing 1 of 3
```

The editor switches to the file, opening it if it isn't open, puts the cursor on the
line and highlights the line in the theme's error or warning color (see **F4**, Syntax
Highlighting Colors). Stepping past the last entry goes back to the first. An error in a
file that isn't on the disk, such as a library unit, is shown but the editor doesn't move.

The IDE keeps the first 32 errors and warnings; the totals count all of them. The line
numbers are from the compile, so editing the file above an error doesn't move its line.
After **F5** runs the program, the IDE starts fresh and the warnings are gone. Use
**F7** to see them again.

## Running the Compiler

The compiler can be run independently of the IDE if desired, like this:

```
DLOAD"COMPILER"
RUN
```

When run like this, the compiler will prompt for a source filename.  A filename can be provided
on the command line like this:

```
DLOAD"COMPILER"
RUN:REM src.pas
```

Where **src.pas** is the source filename.
