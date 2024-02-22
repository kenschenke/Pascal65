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
