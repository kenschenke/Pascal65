# Compiled Unit File

A unit compiled on its own is written to *unit-name*.tpu. The file holds
everything a program that uses the unit needs: the unit's interface, for
resolving and type checking the program, and the unit's intermediate code,
for code generation. Keeping both in one file means the interface and the
code can't be out of date separately. When the compiler recompiles a unit
is described in [Units](../langref/units.md#compiled-units).

It is not necessary to understand this format to use units. It is
documented for compiler maintenance.

## Layout

Words are low byte first.

|Bytes   |Contents                                                    |
|--------|------------------------------------------------------------|
|2       |Magic: `TP` ($54, $50)                                      |
|1       |TPU format version (1)                                      |
|1       |Intermediate code format version of the icode section       |
|1       |Flags. Bit 0 is reserved for overlay units and is 0.        |
|2       |CRC of the unit's source file when it was compiled          |
|2       |CRC of the interface section                                |
|varies  |The used units                                              |
|2       |Length of the interface section                             |
|varies  |The interface section                                       |
|2       |Length of the icode section                                 |
|varies  |The icode section                                           |

Each section starts with its length, so a reader can skip what it doesn't
need.

### Used Units

A count byte, then each unit the unit uses: System first, as every unit
uses it, then the units its interface's **Uses** names, then those its
implementation's **Uses** names. Each is its name (a length byte, then the
characters) and the interface CRC that unit had when this one was compiled.
A library's interface CRC is made from its pre-compiled header the same way.

### Interface Section

A [pre-compiled header](../libraries/header.md) of the unit's interface, as
the parser made it: the records a library's .hdr file holds. The
implementation's declarations aren't in it. The compiler reads it in place
of parsing the unit's source.

The records hold source line numbers, so moving the interface's lines (a
comment added above it, for example) changes the interface's CRC.

### Icode Section

The unit's own intermediate code file, byte for byte: its header (a unit's
kind and its slot count), its imports and frames tables, its init block,
its routines and data, and its last instruction, EOM. Code generation reads
the unit's code from here. See the [introduction](intro.md).

## CRCs

Every CRC is CRC-16/CCITT: polynomial $1021, starting at $FFFF, over the
bytes of the source file or the interface section.

A unit's .tpu file is current when its versions are the compiler's, its
source's CRC matches, and each used unit's interface CRC matches the one
that unit has now.
