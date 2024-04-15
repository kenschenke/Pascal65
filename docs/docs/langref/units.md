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