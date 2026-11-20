# Units

A unit is a separate code module that can contain variables, constants,
functions, and procedures.  A unit is stored in a separate source file
and is included into the program at time of compile.

A unit is made up of two distinct parts: an interface and implementation.
Everything declared in the interface section is accessible to code outside
the unit, including variables, procedures, functions, constants, and
type declarations. Conversely, everything in the implementation section
can only be accessed within the unit.

Units are a powerful tool to encapsulate and organize code in a program.
A game might have a unit to manage the screen, another to track game state,
and another to play sounds.  Units are also a great way to share code
between programs.

## Referencing a Unit

A unit is referenced in your code with the **Uses** statement.

```
Program TestProgram;

Uses <unit-1>, <unit-2>, ..., <unit-n>;
```

## Unit Source File

The source file for a unit must be named unit-name.pas and be located
on the same disk as the source file referencing the unit.

## Unit Interface

The **interface** section of a unit is accessible to code outside the unit.
This section can consist of constants, type definitions, variables, and
function and procedure declarations.  This section always appears first in
the unit source file.

## Unit Implementation

The **implementation** section of a unit is private to the unit itself and
cannot be accessed by any code outside the unit.  Like the interface section,
this section can also consist of constants, type definitions, variables, and
functions and procedures.  This section always appears after the interface
section.

## Unit Syntax

```
Unit <unit-name>;

Uses <other-units>;  (* This is optional *)

Interface

Const  (* optional *)
    <constant defintions>
Type  (* optional *)
    <type definitions>
Var  (* optional *)
    <variables>

<procedure and function declarations>

Implementation

Const  (* optional *)
    <constant defintions>
Type  (* optional *)
    <type definitions>
Var  (* optional *)
    <variables>

<procedure and function declarations>

End.
```
## Compiled Units

The compiler compiles each unit on its own to a compiled unit file named
*unit-name*.tpu, on the same disk as the unit's source. A program that uses
the unit is compiled with the unit's interface and code read from that
file, so a unit is only compiled again when it has changed.

A unit's source can be compiled by itself too, in the IDE or with the
compiler. That writes its .tpu file and nothing else: a unit has no
program to run.

### When a Unit Is Compiled

Before it compiles a program, or a unit, the compiler checks every unit
it uses, and every unit those use, deepest first, as Turbo Pascal's Make
did. A unit is compiled again when:

* it has no .tpu file
* its source has changed since its .tpu file was written
* the .tpu file was written by another version of the compiler
* the interface of a unit it uses has changed

Only a change to a unit's interface affects the units that use it. A
change to its implementation, such as a routine's body, compiles only that
unit. A change to its interface compiles it and the units that use it. If
a unit's interface changes but the interface of a unit that uses it
doesn't, the change goes no further.

Each unit compiled shows its own "Compiling" line. An error in a unit stops
the build, and the error names the unit's source file. In the IDE, **F11**
and **F9** open that file at the error's line.

A unit with no source on the disk keeps the .tpu file it has. A library
unit (one with a .hdr file or **Implementation Library**) is never compiled.

### Rebuilding Every Unit

**F8** in the IDE (Rebuild All) compiles every unit the current file uses,
and every unit those use, whether its .tpu file is current or not, then
the file itself. Library units and units with no source are left alone.

### Circular References

Two units can't use each other, either directly or through other units. The
compiler reports **Circular unit reference** in the source of the unit
where it found the loop.

### Temporary Files

While a unit compiles, the compiler writes the temporary files *zztpu* and
*zzi* followed by the unit's name. They are erased when the compile ends,
whether or not it succeeds.

The file format is described in [Compiled Unit File](../icode/tpu.md).
