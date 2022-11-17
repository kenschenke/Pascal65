# Pascal Syntax

Pascal is similar to other high-level languages but different than most
C-like languages.  All the familiar contructs are present.  The biggest
way in which Pascal differs from many other high-level languages is that
Pascal is not case sensitive for language keywords, functions, procedures,
and variables.  MyVar is the same variable as myVar, myvar, and MYVAR.

For readability purposes, example code in this documentation will be shown
in mixed-case form.

Like C, all Pascal statements must be terminated with a semi-colon.  Almost
all Pascal blocks are also terminated with a semi-colon except the top-level
PROGRAM block, which is terminated with a period.

## Hello World

In observance of the long-standing tradition in programming documentation,
following is a bare-bones example of a Pascal program.

```
PROGRAM helloworld(output);
BEGIN
    writeln('Hello, world!');
END.
```

**Notice the period after the END keyword.**

Because of Pascal's case-insensitivity, the above example could also be written as:

```
Program HelloWorld(output);
Begin
    Writeln('Hello, world!');
End.
```

## Anatomy of a Pascal Program

Every Pascal program starts with a **Program** statement followed by the name of the
program and the program's inputs in parenthesis and a semi-colon.

The **Program** statement is followed by optional sections defining constant values,
type declarations, and variable declarations.
